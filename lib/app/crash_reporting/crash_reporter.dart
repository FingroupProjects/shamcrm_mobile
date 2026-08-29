import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String _telegramCrashBotToken = String.fromEnvironment(
  'TELEGRAM_CRASH_BOT_TOKEN',
  defaultValue: '8926264073:AAEF31-5Bvhnr2Xdz6GIpG5u_KyFbWpA5KM',
);
const String _telegramCrashChatId = String.fromEnvironment(
  'TELEGRAM_CRASH_CHAT_ID',
  defaultValue: '6833674360',
);
const String _telegramCriticalThreadIdValue = String.fromEnvironment(
  'TELEGRAM_CRITICAL_THREAD_ID',
  defaultValue: '',
);
const String _telegramNormalThreadIdValue = String.fromEnvironment(
  'TELEGRAM_NORMAL_THREAD_ID',
  defaultValue: '',
);
const Duration _telegramCrashDuplicateWindow = Duration(seconds: 2);
const Duration _telegramRepeatEscalationWindow = Duration(minutes: 10);
const int _telegramRepeatEscalationThreshold = 3;

final Map<String, DateTime> _recentCrashReports = <String, DateTime>{};
final Map<String, _IssueRepeatStats> _recentIssueStats =
    <String, _IssueRepeatStats>{};

class _CrashSeverity {
  final String emoji;
  final String title;
  final int priority;

  const _CrashSeverity({
    required this.emoji,
    required this.title,
    required this.priority,
  });
}

class _IssueContext {
  final String severityKey;
  final String emoji;
  final String title;
  final int priority;
  final String screen;
  final String screenLabel;
  final String category;
  final String categoryLabel;
  final bool fatal;
  final int repeatCount;
  final int? threadId;

  const _IssueContext({
    required this.severityKey,
    required this.emoji,
    required this.title,
    required this.priority,
    required this.screen,
    required this.screenLabel,
    required this.category,
    required this.categoryLabel,
    required this.fatal,
    required this.repeatCount,
    required this.threadId,
  });
}

class _IssueRepeatStats {
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int count;

  const _IssueRepeatStats({
    required this.firstSeen,
    required this.lastSeen,
    required this.count,
  });

  _IssueRepeatStats next(DateTime now) {
    return _IssueRepeatStats(
      firstSeen: firstSeen,
      lastSeen: now,
      count: count + 1,
    );
  }

  bool isWithinWindow(DateTime now) {
    return now.difference(lastSeen) <= _telegramRepeatEscalationWindow;
  }
}

class _SeverityBadge {
  final String emoji;
  final String label;

  const _SeverityBadge({
    required this.emoji,
    required this.label,
  });
}

Future<void> initializeCrashlytics() async {
  if (Firebase.apps.isEmpty) return;

  FlutterError.onError = (errorDetails) {
    // Layout overflows and known recoverable framework errors are not
    // process-killing crashes.
    final isNonFatal = _isLayoutOverflow(errorDetails.exception) ||
        _isRecoverableFlutterError(
          errorDetails.exception,
          errorDetails.stack,
        );
    if (isNonFatal) {
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
      unawaited(
        reportIssue(
          source: 'flutter_error',
          error: errorDetails.exception,
          stackTrace: errorDetails.stack,
          fatal: false,
        ),
      );
      return;
    }

    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    unawaited(
      reportIssue(
        source: 'flutter_error',
        error: errorDetails.exception,
        stackTrace: errorDetails.stack,
        fatal: true,
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final isNonFatal = _isRecoverableFlutterError(error, stack);
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: !isNonFatal);
    unawaited(
      reportIssue(
        source: 'platform_dispatcher',
        error: error,
        stackTrace: stack,
        fatal: !isNonFatal,
      ),
    );
    return true;
  };

  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
}

Future<void> reportIssue({
  required String source,
  required Object error,
  required StackTrace? stackTrace,
  required bool fatal,
  String? screenHint,
  String? categoryHint,
}) async {
  if (_telegramCrashBotToken.isEmpty || _telegramCrashChatId.isEmpty) {
    return;
  }

  final severity = _classifyIssueSeverity(
    source: source,
    error: error,
    stackTrace: stackTrace,
    fatal: fatal,
  );
  final screen = screenHint ??
      _detectIssueScreen(
        source: source,
        error: error,
        stackTrace: stackTrace,
      );
  final category = categoryHint ??
      _detectIssueCategory(
        source: source,
        error: error,
        stackTrace: stackTrace,
        fatal: fatal,
      );
  final issueContext = _buildIssueContext(
    severity: severity,
    screen: screen,
    category: category,
    fatal: fatal,
  );
  final fingerprint = '$source|$error|${stackTrace?.toString() ?? ''}';
  final now = DateTime.now();
  _recentCrashReports.removeWhere(
    (_, time) => now.difference(time) > const Duration(minutes: 1),
  );

  _recentIssueStats.removeWhere(
    (_, stats) =>
        now.difference(stats.lastSeen) > _telegramRepeatEscalationWindow,
  );

  final lastReportedAt = _recentCrashReports[fingerprint];
  if (lastReportedAt != null &&
      now.difference(lastReportedAt) < _telegramCrashDuplicateWindow) {
    return;
  }
  _recentCrashReports[fingerprint] = now;

  final repeatStats = _registerIssueOccurrence(fingerprint, now);
  final escalatedByRepeat = _shouldEscalateByRepeat(
    fatal: fatal,
    stats: repeatStats,
  );
  final formattedIssue = escalatedByRepeat
      ? _promoteRepeatIssue(issueContext, repeatStats.count)
      : issueContext;

  final stackText = stackTrace?.toString().trim();
  final message = _buildTelegramHtmlMessage(
    issue: formattedIssue,
    source: source,
    error: error,
    stackText: stackText,
    now: now,
    repeatCount: repeatStats.count,
    escalatedByRepeat: escalatedByRepeat,
  );

  try {
    final body = <String, String>{
      'chat_id': _telegramCrashChatId,
      'text': message,
      'disable_web_page_preview': 'true',
      'parse_mode': 'HTML',
    };

    if (formattedIssue.threadId != null) {
      body['message_thread_id'] = formattedIssue.threadId.toString();
    }

    await http
        .post(
          Uri.parse(
            'https://api.telegram.org/bot$_telegramCrashBotToken/sendMessage',
          ),
          body: body,
        )
        .timeout(const Duration(seconds: 5));
  } catch (e, notifyStackTrace) {
    debugPrint('main: Telegram crash notify error: $e');
    debugPrint('main: Telegram crash notify stackTrace: $notifyStackTrace');
  }
}

_IssueRepeatStats _registerIssueOccurrence(String fingerprint, DateTime now) {
  final current = _recentIssueStats[fingerprint];
  if (current == null || !current.isWithinWindow(now)) {
    final fresh = _IssueRepeatStats(
      firstSeen: now,
      lastSeen: now,
      count: 1,
    );
    _recentIssueStats[fingerprint] = fresh;
    return fresh;
  }

  final updated = current.next(now);
  _recentIssueStats[fingerprint] = updated;
  return updated;
}

bool _shouldEscalateByRepeat({
  required bool fatal,
  required _IssueRepeatStats stats,
}) {
  return !fatal &&
      stats.count >= _telegramRepeatEscalationThreshold &&
      stats.isWithinWindow(DateTime.now());
}

_IssueContext _promoteRepeatIssue(_IssueContext issue, int repeatCount) {
  return _IssueContext(
    severityKey: 'critical',
    emoji: '🔥',
    title: 'Repeated issue',
    priority: 1,
    screen: issue.screen,
    screenLabel: issue.screenLabel,
    category: issue.category,
    categoryLabel: issue.categoryLabel,
    fatal: issue.fatal,
    repeatCount: repeatCount,
    threadId: int.tryParse(_telegramCriticalThreadIdValue),
  );
}

String _buildTelegramHtmlMessage({
  required _IssueContext issue,
  required String source,
  required Object error,
  required String? stackText,
  required DateTime now,
  required int repeatCount,
  required bool escalatedByRepeat,
}) {
  final badge = _severityBadgeFor(issue.severityKey);
  final buffer = StringBuffer()
    ..writeln(
      '${badge.emoji} <b>${_escapeTelegramHtml(badge.label)}</b> <i>${_escapeTelegramHtml(issue.title)}</i>',
    )
    ..writeln(
      '<b>${_escapeTelegramHtml(issue.screenLabel)}</b> · <code>${_escapeTelegramHtml(issue.categoryLabel)}</code> · <b>${_escapeTelegramHtml(issue.severityKey.toUpperCase())}</b>',
    )
    ..writeln(
      '<b>Source:</b> <code>${_escapeTelegramHtml(source)}</code>',
    )
    ..writeln(
      '<b>Time:</b> <code>${_escapeTelegramHtml(now.toIso8601String())}</code>',
    )
    ..writeln(
      '<b>Error:</b> <code>${_escapeTelegramHtml(error.toString())}</code>',
    );

  if (repeatCount > 1) {
    buffer.writeln(
      '<b>Repeat:</b> <code>${repeatCount}x</code> in <code>10m</code>',
    );
  }

  if (escalatedByRepeat) {
    buffer.writeln('<b>Escalated:</b> repeated non-fatal issue');
  }

  if (stackText != null && stackText.trim().isNotEmpty) {
    buffer
      ..writeln('<b>Stack:</b>')
      ..writeln(
        '<pre>${_escapeTelegramHtml(_shortStackPreview(stackText))}</pre>',
      );
  }

  return _truncateTelegramMessage(buffer.toString());
}

_SeverityBadge _severityBadgeFor(String severityKey) {
  switch (severityKey) {
    case 'critical':
      return const _SeverityBadge(emoji: '🔥', label: 'CRITICAL');
    case 'high':
      return const _SeverityBadge(emoji: '⚡', label: 'HIGH');
    case 'normal':
      return const _SeverityBadge(emoji: '🟡', label: 'NORMAL');
    default:
      return const _SeverityBadge(emoji: 'ℹ️', label: 'INFO');
  }
}

String _escapeTelegramHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

_IssueContext _buildIssueContext({
  required _CrashSeverity severity,
  required String screen,
  required String category,
  required bool fatal,
}) {
  final threadId = fatal
      ? int.tryParse(_telegramCriticalThreadIdValue)
      : int.tryParse(_telegramNormalThreadIdValue);

  return _IssueContext(
    severityKey: severity.priority == 1
        ? 'critical'
        : severity.priority == 2
            ? 'high'
            : 'normal',
    emoji: severity.emoji,
    title: severity.title,
    priority: severity.priority,
    screen: screen,
    screenLabel: _screenLabelFor(screen),
    category: category,
    categoryLabel: _categoryLabelFor(category),
    fatal: fatal,
    repeatCount: 1,
    threadId: threadId,
  );
}

bool _isLayoutOverflow(Object error) {
  return error.toString().toLowerCase().contains('renderflex overflowed');
}

bool _isRecoverableFlutterError(Object error, StackTrace? stackTrace) {
  final errorText =
      '${error.toString()}\n${stackTrace?.toString() ?? ''}'.toLowerCase();

  if (errorText.contains('missingpluginexception') &&
      errorText.contains('com.shamcrm/network_status')) {
    return true;
  }

  final isNullCheck = errorText.contains('null check operator used on a null value');
  final isOverlayHitTest = errorText.contains('renderbox.hittest') ||
      errorText.contains('_rendertheatermixin') ||
      errorText.contains('overlay.dart');
  return isNullCheck && isOverlayHitTest;
}

_CrashSeverity _classifyIssueSeverity({
  required String source,
  required Object error,
  required StackTrace? stackTrace,
  required bool fatal,
}) {
  final errorText =
      '${error.toString()}\n${stackTrace?.toString() ?? ''}'.toLowerCase();

  if (_isLayoutOverflow(error) ||
      _isRecoverableFlutterError(error, stackTrace)) {
    return const _CrashSeverity(
      emoji: '🟡',
      title: 'Recoverable framework issue',
      priority: 3,
    );
  }

  if (fatal) {
    return const _CrashSeverity(
      emoji: '🔥',
      title: 'Critical crash',
      priority: 1,
    );
  }

  if (errorText.contains('renderflex overflowed') ||
      errorText.contains('listtile background color or ink splashes')) {
    return const _CrashSeverity(
      emoji: '🟡',
      title: 'UI layout issue',
      priority: 3,
    );
  }

  final criticalPatterns = <String>[
    'missingpluginexception',
    'lateinitializationerror',
    'null check operator used on a null value',
    'setstate() called after dispose()',
    'typeerror',
    'rangeerror',
    'bad state: no element',
    'no such method',
  ];

  if (criticalPatterns.any(errorText.contains)) {
    return const _CrashSeverity(
      emoji: '🔥',
      title: 'Critical issue',
      priority: 1,
    );
  }

  final highPatterns = <String>[
    'exception',
    'fluttererror',
    'assertionerror',
    'socketexception',
    'timeoutexception',
  ];

  if (highPatterns.any(errorText.contains) || source == 'flutter_error') {
    return const _CrashSeverity(
      emoji: '⚡',
      title: 'High priority issue',
      priority: 2,
    );
  }

  return const _CrashSeverity(
    emoji: '🟡',
    title: 'Normal issue',
    priority: 3,
  );
}

String _detectIssueScreen({
  required String source,
  required Object error,
  required StackTrace? stackTrace,
}) {
  final haystack =
      '${source.toLowerCase()}\n${error.toString().toLowerCase()}\n${stackTrace?.toString().toLowerCase() ?? ''}';

  final mappings = <String, String>{
    'lib/screens/auth/': 'auth',
    'lib/screens/home_screen.dart': 'home',
    'lib/screens/chats/': 'chat',
    'lib/screens/task/': 'task',
    'lib/screens/lead/': 'lead',
    'lib/screens/deal/': 'deal',
    'lib/screens/dashboard/': 'dashboard',
    'lib/screens/profile/': 'profile',
    'lib/page_2/': 'page_2',
    'lib/api/service/firebase/firebase_api.dart': 'firebase',
    'missingpluginexception': 'native',
    'renderbox.hittest': 'system',
    '_rendertheatermixin': 'system',
    'platform_dispatcher': 'system',
    'flutter_error': 'flutter',
  };

  for (final entry in mappings.entries) {
    if (haystack.contains(entry.key)) {
      return entry.value;
    }
  }

  return 'unknown';
}

String _detectIssueCategory({
  required String source,
  required Object error,
  required StackTrace? stackTrace,
  required bool fatal,
}) {
  final text =
      '${source.toLowerCase()}\n${error.toString().toLowerCase()}\n${stackTrace?.toString().toLowerCase() ?? ''}';

  if (fatal) {
    return 'crash';
  }

  if (text.contains('timeout')) {
    return 'timeout';
  }
  if (text.contains('socket') || text.contains('network')) {
    return 'network';
  }
  if (text.contains('permission')) {
    return 'permission';
  }
  if (text.contains('missingpluginexception')) {
    return 'native_bridge';
  }
  if (text.contains('renderbox.hittest') ||
      text.contains('_rendertheatermixin')) {
    return 'ui';
  }
  if (text.contains('lateinitializationerror')) {
    return 'initialization';
  }
  if (text.contains('assertionerror')) {
    return 'assertion';
  }
  if (text.contains('rangeerror')) {
    return 'data_bounds';
  }

  return 'general';
}

String _screenLabelFor(String screen) {
  switch (screen) {
    case 'auth':
      return 'Auth';
    case 'home':
      return 'Home';
    case 'chat':
      return 'Chat';
    case 'task':
      return 'Task';
    case 'lead':
      return 'Lead';
    case 'deal':
      return 'Deal';
    case 'dashboard':
      return 'Dashboard';
    case 'profile':
      return 'Profile';
    case 'page_2':
      return 'Page 2';
    case 'firebase':
      return 'Firebase';
    case 'native':
      return 'Native';
    case 'ios':
      return 'iOS';
    case 'system':
      return 'System';
    case 'flutter':
      return 'Flutter';
    case 'startup':
      return 'Startup';
    default:
      return 'General';
  }
}

String _categoryLabelFor(String category) {
  switch (category) {
    case 'crash':
      return 'Crash';
    case 'fatal_crash':
      return 'Fatal crash';
    case 'non_fatal':
      return 'Non-fatal';
    case 'network':
      return 'Network';
    case 'timeout':
      return 'Timeout';
    case 'permission':
      return 'Permission';
    case 'native_bridge':
      return 'Native bridge';
    case 'ui':
      return 'UI';
    case 'initialization':
      return 'Init';
    case 'assertion':
      return 'Assertion';
    case 'data_bounds':
      return 'Bounds';
    case 'general':
      return 'General';
    default:
      return category;
  }
}

String _shortStackPreview(String stackText) {
  final lines = stackText
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .take(6)
      .toList();

  if (lines.isEmpty) {
    return stackText;
  }

  return lines.join('\n');
}

String _truncateTelegramMessage(String message) {
  const maxLength = 3900;
  if (message.length <= maxLength) {
    return message;
  }
  return '${message.substring(0, maxLength)}\n\n... truncated';
}

Future<void> recordNonFatalError(
  Object error,
  StackTrace stackTrace, {
  required String reason,
  String? screenHint,
}) async {
  try {
    if (Firebase.apps.isNotEmpty) {
      await FirebaseCrashlytics.instance.setCustomKey('error_source', reason);
      await FirebaseCrashlytics.instance.setCustomKey(
        'issue_severity',
        'normal',
      );
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: false,
      );
    }
    await reportIssue(
      source: reason,
      error: error,
      stackTrace: stackTrace,
      fatal: false,
      screenHint: screenHint,
      categoryHint: 'non_fatal',
    );
  } catch (_) {}
}

Future<void> recordFatalError(
  Object error,
  StackTrace stackTrace, {
  required String reason,
}) async {
  try {
    if (Firebase.apps.isNotEmpty) {
      await FirebaseCrashlytics.instance.setCustomKey('error_source', reason);
      await FirebaseCrashlytics.instance.setCustomKey(
        'issue_severity',
        'critical',
      );
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: true,
      );
    }
    await reportIssue(
      source: reason,
      error: error,
      stackTrace: stackTrace,
      fatal: true,
      categoryHint: 'fatal_crash',
    );
  } catch (_) {}
}

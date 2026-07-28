// Этот файл отвечает за состояние звонка, таймеры и служебные SIP-вычисления экрана.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipScreenCallStateExtension on _SipScreenState {
  bool _isAnsweredElsewhereMessage(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    return normalized.contains('answered elsewhere') ||
        normalized.contains('answered_elsewhere');
  }

  bool _isDeclinedElsewhereMessage(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    return normalized.contains('declined elsewhere') ||
        normalized.contains('declined_elsewhere');
  }

  bool _isServerNumberNotFoundMessage(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    return normalized.contains('not found') ||
        normalized.contains(' 404 ') ||
        normalized.startsWith('404') ||
        normalized.contains(' 399 ');
  }

  bool _isServerForbiddenMessage(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    return normalized.contains('forbidden') ||
        normalized.contains(' 403 ') ||
        normalized.startsWith('403');
  }

  bool _isNetworkLostMessage(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    return normalized.contains('network lost') ||
        normalized.contains('waiting for reconnection');
  }

  bool _isNetworkReconnectMessage(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    return normalized.contains('network restored') ||
        normalized.contains('reconnecting sip');
  }

  bool _isReconnectInProgress(SipUiState state) {
    return state.registrationStatus == SipRegistrationUiStatus.registering &&
        _isNetworkReconnectMessage(state.errorMessage);
  }

  bool _isNetworkUnavailableState(SipUiState state) {
    return state.registrationStatus == SipRegistrationUiStatus.failed &&
        _isNetworkLostMessage(state.errorMessage);
  }

  bool _isRegistrationServerUnavailableMessage(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    return normalized.contains('timeout') ||
        normalized.contains('timed out') ||
        normalized.contains('socket') ||
        normalized.contains('network') ||
        normalized.contains('dns') ||
        normalized.contains('unreachable') ||
        normalized.contains('connection refused');
  }

  bool _isRegistrationAuthErrorMessage(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    return normalized.contains('auth') ||
        normalized.contains('authorization') ||
        normalized.contains('401') ||
        normalized.contains('403') ||
        normalized.contains('forbidden') ||
        normalized.contains('unauthorized') ||
        normalized.contains('логин') ||
        normalized.contains('пароль');
  }

  void _syncCallEffects(SipUiState state) {
    final status = state.callStatus;
    if (_lastObservedCallStatus == status) return;

    _lastObservedCallStatus = status;

    switch (status) {
      case SipCallUiStatus.incoming:
        _stopCallDurationTicker();
        break;
      case SipCallUiStatus.calling:
      case SipCallUiStatus.ringing:
        _stopCallDurationTicker();
        break;
      case SipCallUiStatus.inCall:
        _startCallDurationTicker();
        break;
      case SipCallUiStatus.idle:
      case SipCallUiStatus.ended:
      case SipCallUiStatus.failed:
        _stopCallDurationTicker(reset: true);
        break;
    }
  }

  void _syncSipNotifications(SipUiState state) {
    _syncRegistrationNotifications(state);

    final notice = _resolveSipNotice(state);
    final sourceMessage = state.errorMessage?.trim();
    if (notice == null) {
      return;
    }

    final noticeKey =
        '${state.callStatus.name}|${state.errorMessage ?? ''}|${notice.$1}';

    if (noticeKey == _lastShownSipNoticeKey) {
      return;
    }

    _lastShownSipNoticeKey = noticeKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showSipSnackBar(notice.$1, isError: notice.$2);
      _sipRuntime.clearTransientError(sourceMessage);
    });
  }

  void _syncRegistrationNotifications(SipUiState state) {
    final previousStatus = _lastObservedRegistrationStatus;
    _lastObservedRegistrationStatus = state.registrationStatus;

    if (previousStatus == null) {
      return;
    }

    final notice = _resolveRegistrationNotice(state, previousStatus);
    if (notice == null) {
      return;
    }

    final noticeKey =
        'registration|${previousStatus.name}|${state.registrationStatus.name}|${state.errorMessage ?? ''}|${notice.$1}';
    if (noticeKey == _lastShownRegistrationNoticeKey) {
      return;
    }

    _lastShownRegistrationNoticeKey = noticeKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showSipSnackBar(notice.$1, isError: notice.$2);
    });

    if (state.registrationStatus == SipRegistrationUiStatus.registered &&
        previousStatus != SipRegistrationUiStatus.registered) {
      unawaited(_maybeShowIosForceQuitWarning());
    }
  }

  Future<void> _maybeShowIosForceQuitWarning() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final alreadyPrompted =
        prefs.getBool(_SipScreenState._iosForceQuitWarningPromptedKey) ?? false;
    if (alreadyPrompted) {
      return;
    }

    await prefs.setBool(
      _SipScreenState._iosForceQuitWarningPromptedKey,
      true,
    );

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (!mounted) return;
    //   _showSipSnackBar(
    //     'На iPhone не закрывайте телефонию свайпом из недавних, иначе входящие могут не прийти.',
    //   );
    // }
    // );
  }

  (String, bool)? _resolveRegistrationNotice(
    SipUiState state,
    SipRegistrationUiStatus previousStatus,
  ) {
    final message = state.errorMessage?.trim();

    if (state.registrationStatus == SipRegistrationUiStatus.registered &&
        previousStatus != SipRegistrationUiStatus.registered) {
      return ('Телефония подключена', false);
    }

    if (state.registrationStatus == SipRegistrationUiStatus.disconnected &&
        previousStatus == SipRegistrationUiStatus.registered) {
      return ('Телефония отключена от сервера', false);
    }

    if (state.registrationStatus != SipRegistrationUiStatus.failed) {
      return null;
    }

    if (_isRegistrationAuthErrorMessage(message)) {
      return (
        'Сервер отклонил авторизацию. Проверьте логин, пароль и auth ID',
        true
      );
    }

    if (_isRegistrationServerUnavailableMessage(message)) {
      return (
        'Сервер телефонии не отвечает. Проверьте интернет, адрес сервера и порт',
        true
      );
    }

    if (message == null || message.isEmpty) {
      return ('Не удалось подключиться к серверу телефонии', true);
    }

    return (message, true);
  }

  (String, bool)? _resolveSipNotice(SipUiState state) {
    final message = state.errorMessage?.trim();
    if (message == null || message.isEmpty) {
      return null;
    }

    if (_isAnsweredElsewhereMessage(message)) {
      return ('На другом устройстве уже ответили на этот звонок', false);
    }

    if (_isDeclinedElsewhereMessage(message)) {
      return ('На другом устройстве уже отклонили этот звонок', false);
    }

    if (_isServerNumberNotFoundMessage(message)) {
      return ('Сервер не смог найти маршрут для этого номера', true);
    }

    if (_isServerForbiddenMessage(message)) {
      return (
        'Сервер отклонил этот вызов. Проверьте права или формат номера',
        true
      );
    }

    if (state.callStatus == SipCallUiStatus.failed) {
      return (message, true);
    }

    return null;
  }

  void _startCallDurationTicker() {
    _connectedAt =
        _sipRuntime.currentCallStartedAt ?? _connectedAt ?? DateTime.now();
    _connectedDuration = _sipRuntime.currentCallDuration;
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateView(() {
        _connectedDuration = _sipRuntime.currentCallDuration;
      });
    });
  }

  void _stopCallDurationTicker({bool reset = false}) {
    _callDurationTimer?.cancel();
    _callDurationTimer = null;

    if (reset) {
      _connectedAt = null;
      _connectedDuration = Duration.zero;
    }
  }

  String _callLabel(BuildContext context, SipCallUiStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case SipCallUiStatus.idle:
        return l10n.translate('sip_call_idle');
      case SipCallUiStatus.incoming:
        return l10n.translate('sip_call_incoming');
      case SipCallUiStatus.calling:
        return 'Соединяем звонок';
      case SipCallUiStatus.ringing:
        return 'Подключаем вас к клиенту';
      case SipCallUiStatus.inCall:
        return l10n.translate('sip_call_in_call');
      case SipCallUiStatus.ended:
        return l10n.translate('sip_call_ended');
      case SipCallUiStatus.failed:
        return l10n.translate('sip_call_failed');
    }
  }

  String _resolvedCallLabel(BuildContext context, SipUiState state) {
    if (_isAnsweredElsewhereMessage(state.errorMessage)) {
      return 'Ответили на другом устройстве';
    }
    if (_isDeclinedElsewhereMessage(state.errorMessage)) {
      return 'Отклонено на другом устройстве';
    }
    return _callLabel(context, state.callStatus);
  }

  String _resolvedCallLogLabel(BuildContext context, SipCallLogEntry entry) {
    if (entry.isMissed) {
      return 'Пропущенный';
    }
    if (_isAnsweredElsewhereMessage(entry.endReason)) {
      return 'Ответили на другом устройстве';
    }
    if (_isDeclinedElsewhereMessage(entry.endReason)) {
      return 'Отклонено на другом устройстве';
    }
    return _callLabel(context, entry.result);
  }

  Color _callLogAccentColor(SipCallLogEntry entry) {
    if (entry.isMissed) {
      return _TelephonyVisualColors.red;
    }
    if (_isAnsweredElsewhereMessage(entry.endReason)) {
      return _TelephonyVisualColors.blue;
    }
    if (_isDeclinedElsewhereMessage(entry.endReason)) {
      return _TelephonyVisualColors.amber;
    }
    if (entry.result == SipCallUiStatus.failed) {
      return _TelephonyVisualColors.red;
    }
    return _TelephonyVisualColors.green;
  }

  Color _callLogFillColor(SipCallLogEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color fill(Color color) =>
        isDark ? color.withValues(alpha: 0.16) : color.withValues(alpha: 0.10);
    if (entry.isMissed) {
      return fill(_TelephonyVisualColors.red);
    }
    if (_isAnsweredElsewhereMessage(entry.endReason)) {
      return fill(_TelephonyVisualColors.blue);
    }
    if (_isDeclinedElsewhereMessage(entry.endReason)) {
      return fill(_TelephonyVisualColors.amber);
    }
    if (entry.result == SipCallUiStatus.failed) {
      return fill(_TelephonyVisualColors.red);
    }
    return fill(_TelephonyVisualColors.green);
  }

  IconData _callLogIcon(SipCallLogEntry entry) {
    if (entry.isMissed) {
      return CupertinoIcons.phone_down_fill;
    }
    if (_isAnsweredElsewhereMessage(entry.endReason)) {
      return CupertinoIcons.check_mark_circled_solid;
    }
    if (_isDeclinedElsewhereMessage(entry.endReason)) {
      return CupertinoIcons.xmark_circle_fill;
    }
    return entry.direction == SipCallDirection.incoming
        ? CupertinoIcons.arrow_down_left
        : CupertinoIcons.arrow_up_right;
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool _isActiveCallState(SipCallUiStatus status) {
    return status == SipCallUiStatus.incoming ||
        status == SipCallUiStatus.calling ||
        status == SipCallUiStatus.ringing ||
        status == SipCallUiStatus.inCall;
  }

  String _displayIdentity(SipUiState state) {
    final callDisplayName = _sipRuntime.currentCallDisplayName?.trim();
    final callTarget = _sipRuntime.currentCallTarget?.trim();
    final raw = (callDisplayName?.isNotEmpty == true
            ? callDisplayName!
            : state.remoteIdentity?.trim().isNotEmpty == true
                ? state.remoteIdentity!.trim()
                : callTarget?.isNotEmpty == true
                    ? callTarget!
                    : _sipIdController.text.trim())
        .trim();

    if (raw.isEmpty) return 'Неизвестно';

    var value = raw;
    if (value.startsWith('sip:')) {
      value = value.substring(4);
    }
    if (value.contains('@')) {
      value = value.split('@').first;
    }
    return _restoreTajikPlusForDisplay(value);
  }

  String _callHint(SipUiState state) {
    if (_isAnsweredElsewhereMessage(state.errorMessage)) {
      return 'Этот вызов уже приняли на другом устройстве.';
    }
    if (_isDeclinedElsewhereMessage(state.errorMessage)) {
      return 'Этот вызов уже отклонили на другом устройстве.';
    }

    switch (state.callStatus) {
      case SipCallUiStatus.incoming:
        return 'Входящий вызов. Звучит сигнал вызова.';
      case SipCallUiStatus.calling:
        return 'Исходящий вызов. Включен сигнал ожидания ответа.';
      case SipCallUiStatus.ringing:
        return 'Абонент уведомлен. Ожидаем ответ.';
      case SipCallUiStatus.inCall:
        return 'Соединение активно.';
      case SipCallUiStatus.failed:
        return 'Не удалось завершить вызов успешно.';
      case SipCallUiStatus.ended:
        return 'Вызов завершен.';
      case SipCallUiStatus.idle:
        return 'Готов к новому вызову.';
    }
  }

  bool _isDarkSipTheme(BuildContext context) {
    // Временно принудительно оставляем SIP только в светлой теме,
    // чтобы пользователи не видели тёмный фон во время звонка.
    return false;
  }

  List<Color> _callGradient(bool isDark) {
    return isDark
        ? _G.activeBg
        : const [
            Color(0xFFF8FAFD),
            Color(0xFFEFF4FF),
            Color(0xFFF3F7FF),
          ];
  }

  Color _callPrimaryText(bool isDark) {
    return isDark ? _G.textPrimary : _G.lightText;
  }

  Color _callSecondaryText(bool isDark) {
    return isDark ? _G.textSecondary : _G.lightSubtext;
  }

  Color _callTertiaryText(bool isDark) {
    return isDark ? _G.textTertiary : const Color(0xFF7C8CA5);
  }

  Color _callGlassFill(bool isDark) {
    return isDark ? _G.glassFill : const Color(0xDFFFFFFF);
  }

  Color _callGlassBorder(bool isDark) {
    return isDark ? _G.glassBorder : const Color(0xFFE1EAF6);
  }
}

String _restoreTajikPlusForDisplay(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.startsWith('+')) {
    return trimmed;
  }

  final phoneFormattedOnly = RegExp(r'^[0-9\s().-]+$').hasMatch(trimmed);
  if (!phoneFormattedOnly) {
    return trimmed;
  }

  final digits = trimmed.replaceAll(RegExp(r'[\s().-]'), '');
  if (RegExp(r'^992\d{9}$').hasMatch(digits)) {
    return '+$digits';
  }

  return trimmed;
}

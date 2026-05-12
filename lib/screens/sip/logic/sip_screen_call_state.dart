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

  void _syncCallEffects(SipUiState state) {
    final status = state.callStatus;
    if (_lastObservedCallStatus == status) return;

    _lastObservedCallStatus = status;

    switch (status) {
      case SipCallUiStatus.incoming:
        _stopCallDurationTicker();
        unawaited(_playFeedbackLoop('audio/get.mp3'));
        break;
      case SipCallUiStatus.calling:
      case SipCallUiStatus.ringing:
        _stopCallDurationTicker();
        unawaited(_stopFeedbackLoop());
        break;
      case SipCallUiStatus.inCall:
        _startCallDurationTicker();
        unawaited(_stopFeedbackLoop());
        break;
      case SipCallUiStatus.idle:
      case SipCallUiStatus.ended:
      case SipCallUiStatus.failed:
        _stopCallDurationTicker(reset: true);
        unawaited(_stopFeedbackLoop());
        break;
    }
  }

  void _syncSipNotifications(SipUiState state) {
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

  Future<void> _playFeedbackLoop(String assetPath) async {
    if (_activeFeedbackAsset == assetPath) return;
    _activeFeedbackAsset = assetPath;

    try {
      await _callFeedbackPlayer.stop();
      await _callFeedbackPlayer.setReleaseMode(ReleaseMode.loop);
      await _callFeedbackPlayer.play(AssetSource(assetPath));
    } catch (_) {}
  }

  Future<void> _stopFeedbackLoop() async {
    _activeFeedbackAsset = null;
    try {
      await _callFeedbackPlayer.stop();
    } catch (_) {}
  }

  void _startCallDurationTicker() {
    _connectedAt ??= DateTime.now();
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final connectedAt = _connectedAt;
      if (!mounted || connectedAt == null) return;
      _updateView(() {
        _connectedDuration = DateTime.now().difference(connectedAt);
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
        return l10n.translate('sip_call_calling');
      case SipCallUiStatus.ringing:
        return l10n.translate('sip_call_ringing');
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
    if (_isAnsweredElsewhereMessage(entry.endReason)) {
      return 'Ответили на другом устройстве';
    }
    if (_isDeclinedElsewhereMessage(entry.endReason)) {
      return 'Отклонено на другом устройстве';
    }
    return _callLabel(context, entry.result);
  }

  Color _callLogAccentColor(SipCallLogEntry entry) {
    if (_isAnsweredElsewhereMessage(entry.endReason)) {
      return const Color(0xFF2563EB);
    }
    if (_isDeclinedElsewhereMessage(entry.endReason)) {
      return const Color(0xFFF59E0B);
    }
    if (entry.result == SipCallUiStatus.failed) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF22C55E);
  }

  Color _callLogFillColor(SipCallLogEntry entry) {
    if (_isAnsweredElsewhereMessage(entry.endReason)) {
      return const Color(0xFFEFF6FF);
    }
    if (_isDeclinedElsewhereMessage(entry.endReason)) {
      return const Color(0xFFFFF7ED);
    }
    if (entry.result == SipCallUiStatus.failed) {
      return const Color(0xFFFEF2F2);
    }
    return const Color(0xFFF0FDF4);
  }

  IconData _callLogIcon(SipCallLogEntry entry) {
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
    final raw = (state.remoteIdentity?.trim().isNotEmpty == true
            ? state.remoteIdentity!.trim()
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
    return value;
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

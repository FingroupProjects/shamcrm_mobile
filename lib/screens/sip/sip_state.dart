import 'package:flutter/foundation.dart';
import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:crm_task_manager/utils/utf16_sanitizer.dart';

enum SipRegistrationUiStatus {
  disconnected,
  registering,
  registered,
  failed,
}

enum SipCallUiStatus {
  idle,
  incoming,
  calling,
  ringing,
  inCall,
  ended,
  failed,
}

enum SipCallDirection {
  incoming,
  outgoing,
}

enum SipTransportUi {
  ws,
  tcp,
  udp,
}

@immutable
class SipCallLogEntry {
  final String id;
  final String? serverCallId;
  final int? serverLeadId;
  final String target;
  final String dialTarget;
  final SipCallDirection direction;
  final SipCallUiStatus result;
  final DateTime timestamp;
  final Duration? duration;
  final String? endReason;
  final bool isMissed;
  final CallType? serverCallType;

  const SipCallLogEntry({
    required this.id,
    this.serverCallId,
    this.serverLeadId,
    required this.target,
    required this.dialTarget,
    required this.direction,
    required this.result,
    required this.timestamp,
    this.duration,
    this.endReason,
    this.isMissed = false,
    this.serverCallType,
  });

  factory SipCallLogEntry.fromServerCall(CallLogEntry entry) {
    final isMissed = entry.callType == CallType.missed;
    return SipCallLogEntry(
      id: 'server_${entry.id}',
      serverCallId: entry.id,
      serverLeadId: entry.leadId,
      target: sanitizeUtf16(
        entry.leadName.trim().isNotEmpty && entry.leadName != 'Неизвестно'
            ? entry.leadName
            : entry.phoneNumber,
      ),
      dialTarget: sanitizeUtf16(entry.phoneNumber),
      direction: entry.callType == CallType.outgoing
          ? SipCallDirection.outgoing
          : SipCallDirection.incoming,
      result: isMissed ? SipCallUiStatus.ended : SipCallUiStatus.ended,
      timestamp: entry.callDate,
      duration: entry.duration,
      endReason: isMissed ? 'Пропущенный вызов' : null,
      isMissed: isMissed,
      serverCallType: entry.callType,
    );
  }

  CallLogEntry toCallLogEntry() {
    return CallLogEntry(
      id: serverCallId ?? id,
      leadId: serverLeadId,
      leadName: target,
      phoneNumber: dialTarget,
      callDate: timestamp,
      callType: serverCallType ??
          (isMissed
              ? CallType.missed
              : direction == SipCallDirection.outgoing
                  ? CallType.outgoing
                  : CallType.incoming),
      duration: duration,
    );
  }
}

@immutable
class SipUiState {
  static const Object _serverCallFilterSentinel = Object();

  final String server;
  final String login;
  final String password;
  final String sipId;
  final SipTransportUi transport;
  final int port;
  final SipRegistrationUiStatus registrationStatus;
  final SipCallUiStatus callStatus;
  final String? errorMessage;
  final String? remoteIdentity;
  final bool isMuted;
  final bool isSpeakerOn;
  final List<SipCallLogEntry> callLogs;
  final List<SipCallLogEntry> serverCallLogs;
  final bool isServerCallLogsLoading;
  final bool isServerCallLogsLoadingMore;
  final CallType? serverCallFilter;
  final String serverCallSearchQuery;
  final int serverCallLogsCurrentPage;
  final int serverCallLogsTotalPages;
  final bool allServerCallLogsFetched;

  const SipUiState({
    required this.server,
    required this.login,
    required this.password,
    required this.sipId,
    required this.transport,
    required this.port,
    required this.registrationStatus,
    required this.callStatus,
    this.errorMessage,
    this.remoteIdentity,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.callLogs,
    required this.serverCallLogs,
    required this.isServerCallLogsLoading,
    required this.isServerCallLogsLoadingMore,
    required this.serverCallFilter,
    required this.serverCallSearchQuery,
    required this.serverCallLogsCurrentPage,
    required this.serverCallLogsTotalPages,
    required this.allServerCallLogsFetched,
  });

  factory SipUiState.initial() {
    return const SipUiState(
      server: '',
      login: '',
      password: '',
      sipId: '',
      transport: SipTransportUi.udp,
      port: 5060,
      registrationStatus: SipRegistrationUiStatus.disconnected,
      callStatus: SipCallUiStatus.idle,
      errorMessage: null,
      remoteIdentity: null,
      isMuted: false,
      isSpeakerOn: false,
      callLogs: <SipCallLogEntry>[],
      serverCallLogs: <SipCallLogEntry>[],
      isServerCallLogsLoading: false,
      isServerCallLogsLoadingMore: false,
      serverCallFilter: null,
      serverCallSearchQuery: '',
      serverCallLogsCurrentPage: 1,
      serverCallLogsTotalPages: 1,
      allServerCallLogsFetched: false,
    );
  }

  SipUiState copyWith({
    String? server,
    String? login,
    String? password,
    String? sipId,
    SipTransportUi? transport,
    int? port,
    SipRegistrationUiStatus? registrationStatus,
    SipCallUiStatus? callStatus,
    String? errorMessage,
    bool clearError = false,
    String? remoteIdentity,
    bool clearRemoteIdentity = false,
    bool? isMuted,
    bool? isSpeakerOn,
    List<SipCallLogEntry>? callLogs,
    List<SipCallLogEntry>? serverCallLogs,
    bool? isServerCallLogsLoading,
    bool? isServerCallLogsLoadingMore,
    Object? serverCallFilter = _serverCallFilterSentinel,
    String? serverCallSearchQuery,
    int? serverCallLogsCurrentPage,
    int? serverCallLogsTotalPages,
    bool? allServerCallLogsFetched,
  }) {
    return SipUiState(
      server: server ?? this.server,
      login: login ?? this.login,
      password: password ?? this.password,
      sipId: sipId ?? this.sipId,
      transport: transport ?? this.transport,
      port: port ?? this.port,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      callStatus: callStatus ?? this.callStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      remoteIdentity:
          clearRemoteIdentity ? null : (remoteIdentity ?? this.remoteIdentity),
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      callLogs: callLogs ?? this.callLogs,
      serverCallLogs: serverCallLogs ?? this.serverCallLogs,
      isServerCallLogsLoading:
          isServerCallLogsLoading ?? this.isServerCallLogsLoading,
      isServerCallLogsLoadingMore:
          isServerCallLogsLoadingMore ?? this.isServerCallLogsLoadingMore,
      serverCallFilter: identical(
        serverCallFilter,
        _serverCallFilterSentinel,
      )
          ? this.serverCallFilter
          : serverCallFilter as CallType?,
      serverCallSearchQuery:
          serverCallSearchQuery ?? this.serverCallSearchQuery,
      serverCallLogsCurrentPage:
          serverCallLogsCurrentPage ?? this.serverCallLogsCurrentPage,
      serverCallLogsTotalPages:
          serverCallLogsTotalPages ?? this.serverCallLogsTotalPages,
      allServerCallLogsFetched:
          allServerCallLogsFetched ?? this.allServerCallLogsFetched,
    );
  }
}

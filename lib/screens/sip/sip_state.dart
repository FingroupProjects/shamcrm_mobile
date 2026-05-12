import 'package:flutter/foundation.dart';

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
  final String target;
  final SipCallDirection direction;
  final SipCallUiStatus result;
  final DateTime timestamp;
  final Duration? duration;
  final String? endReason;

  const SipCallLogEntry({
    required this.target,
    required this.direction,
    required this.result,
    required this.timestamp,
    this.duration,
    this.endReason,
  });
}

@immutable
class SipUiState {
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
    );
  }
}

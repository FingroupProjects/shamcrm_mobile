import AVFAudio
import CallKit
import Flutter
import PushKit
import StoreKit
import UIKit
import linphone

private enum CallKitBranding {
    static let appName = "shamCRM"
    static let incomingFallbackHandle = "Входящий звонок"
}

private enum NativeSipPushConfiguration {
    static let appleTeamId = "D8D872QMNJ"

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.softtech.crmTaskManager"
    }

    static var linphoneProvider: String {
        #if DEBUG
        return "apns.dev"
        #else
        return "apns"
        #endif
    }
}

private enum CallKitAvailabilityPolicy {
    static var isAvailable: Bool {
        !isChinaStorefrontOrRegion
    }

    private static var isChinaStorefrontOrRegion: Bool {
        if #available(iOS 13.0, *) {
            if SKPaymentQueue.default().storefront?.countryCode.uppercased() == "CHN" {
                return true
            }
        }

        if Locale.current.regionCode?.uppercased() == "CN" {
            return true
        }

        if TimeZone.current.identifier.uppercased().contains("SHANGHAI") {
            return true
        }

        return false
    }
}

private struct NativeSipSnapshot: Codable {
    var registrationState: String
    var callState: String
    var remoteIdentity: String?
    var message: String?
    var muted: Bool
    var speakerOn: Bool
    var persistentEnabled: Bool
    var appForeground: Bool
    var callUUID: String?
    var callId: String?
    var sipCallId: String?

    static func initial() -> NativeSipSnapshot {
        NativeSipSnapshot(
            registrationState: "disconnected",
            callState: "idle",
            remoteIdentity: nil,
            message: nil,
            muted: false,
            speakerOn: false,
            persistentEnabled: false,
            appForeground: UIApplication.shared.applicationState == .active,
            callUUID: nil,
            callId: nil,
            sipCallId: nil
        )
    }

    func toFlutterDictionary() -> [String: Any] {
        [
            "registrationState": registrationState,
            "callState": callState,
            "remoteIdentity": remoteIdentity ?? NSNull(),
            "message": message ?? NSNull(),
            "muted": muted,
            "speakerOn": speakerOn,
            "persistentEnabled": persistentEnabled,
            "appForeground": appForeground,
            "callUUID": callUUID ?? NSNull(),
            "callId": callId ?? NSNull(),
            "sipCallId": sipCallId ?? NSNull(),
        ]
    }
}

private struct QueuedCallAction: Codable {
    let action: String
    let callUUID: String
    let handle: String?
    let callerName: String?
    let callId: String?
    let fromUri: String?
    let toUri: String?
    let sipUri: String?
    let timestamp: TimeInterval

    func toFlutterDictionary() -> [String: Any] {
        [
            "action": action,
            "callUUID": callUUID,
            "callId": callId ?? NSNull(),
            "remoteIdentity": handle ?? NSNull(),
            "callerName": callerName ?? NSNull(),
            "fromUri": fromUri ?? NSNull(),
            "toUri": toUri ?? NSNull(),
            "sipUri": sipUri ?? NSNull(),
            "timestamp": timestamp,
        ]
    }
}

private struct NativeDiagnosticEntry: Codable {
    let timestamp: TimeInterval
    let event: String
    let details: [String: String]

    func toFlutterDictionary() -> [String: Any] {
        [
            "timestamp": timestamp,
            "event": event,
            "details": details,
        ]
    }
}

struct VoIPIncomingPayload {
    // Creation time from the telephony backend. APNs delivery can be delayed
    // while a device is offline, so delivery time is not a call timestamp.
    let issuedAt: Date?
    let eventType: String
    let uuid: UUID
    let callId: String?
    let handle: String
    let callerName: String?
    let hasVideo: Bool
    let fromUri: String?
    let toUri: String?
    let sipUri: String?
    let bridgeUri: String?

    func toFlutterDictionary() -> [String: Any] {
        [
            "issuedAtMs": issuedAt.map { Int64($0.timeIntervalSince1970 * 1000) } ?? NSNull(),
            "eventType": eventType,
            "callUUID": uuid.uuidString,
            "callId": callId ?? NSNull(),
            "remoteIdentity": handle,
            "callerName": callerName ?? NSNull(),
            "hasVideo": hasVideo,
            "fromUri": fromUri ?? NSNull(),
            "toUri": toUri ?? NSNull(),
            "sipUri": sipUri ?? NSNull(),
            "bridgeUri": bridgeUri ?? NSNull(),
        ]
    }

    static func from(userInfo: [AnyHashable: Any]) -> VoIPIncomingPayload {
        let dataDictionary = userInfo["data"] as? [String: Any]
        let callDictionary = userInfo["call"] as? [String: Any]
        let sipDictionary = userInfo["sip"] as? [String: Any]
        let apsDictionary = userInfo["aps"] as? [String: Any]
        let alertDictionary = apsDictionary?["alert"] as? [String: Any]

        let rawUUID = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: ["uuid", "call_uuid", "callUUID"]
        )

        let issuedAt = firstDate(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: ["call_started_at_ms", "created_at_ms", "sent_at_ms", "issued_at_ms", "timestamp_ms", "call_started_at", "created_at", "sent_at", "issued_at", "timestamp"]
        )
        let eventType = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: ["type", "event"]
        )?.lowercased() ?? "incoming_call"

        let callId = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: ["call_id", "callId", "id"]
        )
        let uuid = UUID(uuidString: rawUUID ?? "") ?? UUID(uuidString: callId ?? "") ?? UUID()

        let callerName = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary, alertDictionary],
            keys: [
                "lead_name",
                "caller_name",
                "callerName",
                "display_name",
                "displayName",
                "from_name",
                "name",
                "title",
            ]
        )

        let handle = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: [
                "caller_number",
                "handle",
                "remote_identity",
                "remoteIdentity",
                "number",
                "phone",
                "phone_number",
                "phoneNumber",
                "from",
                "from_uri",
                "fromUri",
                "from_number",
                "fromNumber",
            ]
        ) ?? callerName ?? "Unknown"

        let fromUri = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: ["from_uri", "fromUri", "from", "caller_number"]
        )

        let toUri = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: ["to_uri", "toUri", "to", "destination_number"]
        )

        let sipUri = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: ["sip_uri", "sipUri", "invite_uri", "inviteUri", "uri"]
        )

        let bridgeUri = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: ["bridge_uri", "bridgeUri", "answer_uri", "answerUri", "callback_uri", "callbackUri"]
        )

        let hasVideo = firstBool(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: ["has_video", "hasVideo", "video", "is_video"]
        ) ?? false

        return VoIPIncomingPayload(
            issuedAt: issuedAt,
            eventType: eventType,
            uuid: uuid,
            callId: callId,
            handle: handle,
            callerName: callerName,
            hasVideo: hasVideo,
            fromUri: fromUri,
            toUri: toUri,
            sipUri: sipUri,
            bridgeUri: bridgeUri
        )
    }

    var isTerminationEvent: Bool {
        ["call_cancelled", "call_canceled", "call_ended", "call_end"].contains(eventType)
    }

    private static func firstDate(
        in root: [AnyHashable: Any],
        nested: [[String: Any]?],
        keys: [String]
    ) -> Date? {
        for key in keys {
            if let parsed = parseDate(root[key]) { return parsed }
        }
        for dictionary in nested {
            guard let dictionary else { continue }
            for key in keys {
                if let parsed = parseDate(dictionary[key]) { return parsed }
            }
        }
        return nil
    }

    private static func parseDate(_ value: Any?) -> Date? {
        let numeric: Double?
        switch value {
        case let value as NSNumber: numeric = value.doubleValue
        case let value as String: numeric = Double(value.trimmingCharacters(in: .whitespacesAndNewlines))
        default: numeric = nil
        }
        if let numeric, numeric > 0 {
            return Date(timeIntervalSince1970: numeric > 10_000_000_000 ? numeric / 1000 : numeric)
        }
        guard let string = value as? String else { return nil }
        return ISO8601DateFormatter().date(from: string.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func firstString(
        in root: [AnyHashable: Any],
        nested: [[String: Any]?],
        keys: [String]
    ) -> String? {
        for key in keys {
            if let value = root[key] as? String, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        for dictionary in nested {
            guard let dictionary else { continue }
            for key in keys {
                if let value = dictionary[key] as? String, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return value.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

        return nil
    }

    private static func firstBool(
        in root: [AnyHashable: Any],
        nested: [[String: Any]?],
        keys: [String]
    ) -> Bool? {
        for key in keys {
            if let parsed = parseBool(root[key]) {
                return parsed
            }
        }

        for dictionary in nested {
            guard let dictionary else { continue }
            for key in keys {
                if let parsed = parseBool(dictionary[key]) {
                    return parsed
                }
            }
        }

        return nil
    }

    private static func parseBool(_ value: Any?) -> Bool? {
        switch value {
        case let value as Bool:
            return value
        case let value as Int:
            return value != 0
        case let value as String:
            switch value.lowercased() {
            case "1", "true", "yes":
                return true
            case "0", "false", "no":
                return false
            default:
                return nil
            }
        default:
            return nil
        }
    }
}

private struct NativeSipRegistrationConfig: Codable {
    let server: String
    let login: String
    let password: String
    let port: Int
    let transport: String
    let authUser: String

    static func from(arguments: [String: Any]) -> NativeSipRegistrationConfig? {
        guard
            let rawServer = arguments["server"] as? String,
            let rawLogin = arguments["login"] as? String,
            let password = arguments["password"] as? String,
            let port = arguments["port"] as? Int
        else {
            return nil
        }

        let server = rawServer.trimmingCharacters(in: .whitespacesAndNewlines)
        let login = rawLogin.trimmingCharacters(in: .whitespacesAndNewlines)
        let authUser = ((arguments["authUser"] as? String) ?? login)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let transport = ((arguments["transport"] as? String) ?? "udp")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !server.isEmpty, !login.isEmpty, !password.isEmpty, !authUser.isEmpty else {
            return nil
        }

        return NativeSipRegistrationConfig(
            server: server,
            login: login,
            password: password,
            port: port,
            transport: transport == "tcp" ? "tcp" : "udp",
            authUser: authUser
        )
    }
}

protocol IOSVoIPPushManagerDelegate: AnyObject {
    func voipPushManager(_ manager: IOSVoIPPushManager, didUpdate token: String)
    func voipPushManagerDidInvalidateToken(_ manager: IOSVoIPPushManager)
    func voipPushManager(
        _ manager: IOSVoIPPushManager,
        didReceiveIncoming payload: VoIPIncomingPayload,
        completion: @escaping () -> Void
    )
}

final class IOSVoIPPushManager: NSObject, PKPushRegistryDelegate {
    weak var delegate: IOSVoIPPushManagerDelegate?
    private var registry: PKPushRegistry?

    func start() {
        guard registry == nil else { return }

        let registry = PKPushRegistry(queue: DispatchQueue.main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        self.registry = registry
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        guard type == .voIP else { return }
        let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        delegate?.voipPushManager(self, didUpdate: token)
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        delegate?.voipPushManagerDidInvalidateToken(self)
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        guard type == .voIP else {
            completion()
            return
        }

        let parsedPayload = VoIPIncomingPayload.from(userInfo: payload.dictionaryPayload)
        delegate?.voipPushManager(self, didReceiveIncoming: parsedPayload, completion: completion)
    }
}

protocol IOSCallKitManagerDelegate: AnyObject {
    func callKitManager(
        _ manager: IOSCallKitManager,
        didReceiveAnswerFor callUUID: UUID,
        payload: VoIPIncomingPayload?
    )
    func callKitManager(
        _ manager: IOSCallKitManager,
        didReceiveEndFor callUUID: UUID,
        payload: VoIPIncomingPayload?
    )
    func callKitManagerDidActivateAudioSession(_ manager: IOSCallKitManager)
    func callKitManagerDidDeactivateAudioSession(_ manager: IOSCallKitManager)
    func callKitManagerDidReset(_ manager: IOSCallKitManager)
}

final class IOSCallKitManager: NSObject, CXProviderDelegate {
    weak var delegate: IOSCallKitManagerDelegate?

    private let provider: CXProvider
    private let callController = CXCallController()
    private var payloadsByUUID: [UUID: VoIPIncomingPayload] = [:]
    private var pendingAnswerActions: [UUID: CXAnswerCallAction] = [:]

    override init() {
        let configuration = CXProviderConfiguration(localizedName: "shamCRM")
        configuration.supportsVideo = false
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.includesCallsInRecents = false
        configuration.supportedHandleTypes = [.phoneNumber, .generic]
        provider = CXProvider(configuration: configuration)

        super.init()
        provider.setDelegate(self, queue: nil)
    }

    func reportIncomingCall(
        payload: VoIPIncomingPayload,
        completion: @escaping (Error?) -> Void
    ) {
        payloadsByUUID[payload.uuid] = payload
        let update = buildCallUpdate(for: payload)

        provider.reportNewIncomingCall(with: payload.uuid, update: update) { [weak self] error in
            if error != nil {
                self?.payloadsByUUID.removeValue(forKey: payload.uuid)
            }
            completion(error)
        }
    }

    func refreshIncomingCallDisplay(callUUID: UUID, payload: VoIPIncomingPayload) {
        payloadsByUUID[callUUID] = payload
        provider.reportCall(with: callUUID, updated: buildCallUpdate(for: payload))
    }

    func payload(for callUUID: UUID) -> VoIPIncomingPayload? {
        payloadsByUUID[callUUID]
    }

    func reportCallConnected(callUUID: UUID) {
        if let action = pendingAnswerActions.removeValue(forKey: callUUID) {
            action.fulfill()
        }
    }

    func completeAnswerAction(callUUID: UUID, accepted: Bool) {
        guard let action = pendingAnswerActions.removeValue(forKey: callUUID) else {
            return
        }

        if accepted {
            action.fulfill()
        } else {
            action.fail()
        }
    }

    func reportCallEnded(callUUID: UUID, reason: CXCallEndedReason) {
        if let action = pendingAnswerActions.removeValue(forKey: callUUID) {
            if reason == .failed {
                action.fail()
            } else {
                action.fulfill()
            }
        }

        payloadsByUUID.removeValue(forKey: callUUID)
        provider.reportCall(with: callUUID, endedAt: Date(), reason: reason)
    }

    func requestEndCall(callUUID: UUID, completion: @escaping (Error?) -> Void) {
        let action = CXEndCallAction(call: callUUID)
        let transaction = CXTransaction(action: action)
        callController.request(transaction, completion: completion)
    }

    private func handleType(for handle: String) -> CXHandle.HandleType {
        let normalized = handle.replacingOccurrences(of: "+", with: "")
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: normalized))
            ? .phoneNumber
            : .generic
    }

    private func buildCallUpdate(for payload: VoIPIncomingPayload) -> CXCallUpdate {
        let displayHandle = displayHandle(for: payload)
        let displayName = displayCallerName(for: payload)

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: handleType(for: displayHandle), value: displayHandle)
        update.localizedCallerName = displayName
        update.hasVideo = payload.hasVideo
        update.supportsDTMF = true
        update.supportsGrouping = false
        update.supportsHolding = false
        update.supportsUngrouping = false
        return update
    }

    private func displayCallerName(for payload: VoIPIncomingPayload) -> String? {
        if let callerName = payload.callerName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !callerName.isEmpty,
           callerName.lowercased() != "unknown" {
            return callerName
        }

        return nil
    }

    private func displayHandle(for payload: VoIPIncomingPayload) -> String {
        let candidates = [
            payload.handle,
            payload.fromUri,
            payload.sipUri,
        ]

        for candidate in candidates {
            let normalized = normalizedSipIdentity(candidate)
            guard !normalized.isEmpty else { continue }
            if normalized.lowercased() == "unknown" {
                continue
            }
            if normalized == CallKitBranding.appName {
                continue
            }
            return normalized
        }

        return CallKitBranding.incomingFallbackHandle
    }

    private func normalizedSipIdentity(_ value: String?) -> String {
        guard var normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !normalized.isEmpty else {
            return ""
        }

        if normalized.lowercased().hasPrefix("sip:") {
            normalized = String(normalized.dropFirst(4))
        }

        if let semicolonIndex = normalized.firstIndex(of: ";") {
            normalized = String(normalized[..<semicolonIndex])
        }

        if let atIndex = normalized.firstIndex(of: "@") {
            normalized = String(normalized[..<atIndex])
        }

        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized
    }

    func providerDidReset(_ provider: CXProvider) {
        payloadsByUUID.removeAll()
        pendingAnswerActions.removeAll()
        delegate?.callKitManagerDidReset(self)
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        pendingAnswerActions[action.callUUID] = action
        delegate?.callKitManager(self, didReceiveAnswerFor: action.callUUID, payload: payloadsByUUID[action.callUUID])
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        pendingAnswerActions.removeValue(forKey: action.callUUID)
        let payload = payloadsByUUID[action.callUUID]
        payloadsByUUID.removeValue(forKey: action.callUUID)
        action.fulfill()
        delegate?.callKitManager(self, didReceiveEndFor: action.callUUID, payload: payload)
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        delegate?.callKitManagerDidActivateAudioSession(self)
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        delegate?.callKitManagerDidDeactivateAudioSession(self)
    }
}

private enum DeferredNativeCallAction {
    case answer
    case decline
    case end
}

private func nativeSipManager(from core: OpaquePointer?) -> IOSNativeSipManager? {
    guard let core, let userData = linphone_core_get_user_data(core) else {
        return nil
    }
    return Unmanaged<IOSNativeSipManager>.fromOpaque(userData).takeUnretainedValue()
}

private func nativeSipCallStateChanged(
    _ core: OpaquePointer?,
    _ call: OpaquePointer?,
    _ state: LinphoneCallState,
    _ message: UnsafePointer<CChar>?
) {
    nativeSipManager(from: core)?.handleLinphoneCallStateChanged(
        call: call,
        state: state,
        message: IOSNativeSipManager.string(from: message)
    )
}

private func nativeSipAccountRegistrationStateChanged(
    _ core: OpaquePointer?,
    _ account: OpaquePointer?,
    _ state: LinphoneRegistrationState,
    _ message: UnsafePointer<CChar>?
) {
    nativeSipManager(from: core)?.handleLinphoneRegistrationStateChanged(
        account: account,
        state: state,
        message: IOSNativeSipManager.string(from: message)
    )
}

final class IOSNativeSipManager: NSObject, FlutterStreamHandler {
    private enum Constants {
        static let methodChannelName = "com.shamcrm/native_sip/methods"
        static let eventChannelName = "com.shamcrm/native_sip/events"
        static let snapshotKey = "ios_native_sip_snapshot_v1"
        static let voipTokenKey = "ios_native_sip_voip_token"
        static let pendingCallActionsKey = "ios_native_sip_pending_call_actions_v1"
        static let registrationConfigKey = "ios_native_sip_registration_config_v1"
        static let diagnosticLogsKey = "ios_native_sip_diagnostic_logs_v1"
        static let diagnosticLogsLimit = 5000
        static let maximumIncomingPushAge: TimeInterval = 120
    }

    private let defaults = UserDefaults.standard
    private let methodChannel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel
    private let voipPushManager = IOSVoIPPushManager()
    private lazy var callKitManager: IOSCallKitManager? = {
        guard CallKitAvailabilityPolicy.isAvailable else { return nil }
        return IOSCallKitManager()
    }()

    private var eventSink: FlutterEventSink?
    private var pendingEvents: [[String: Any]] = []
    private var snapshot: NativeSipSnapshot
    private var initialized = false

    private var core: OpaquePointer?
    private var coreCallbacks: OpaquePointer?
    private var account: OpaquePointer?
    private var currentCall: OpaquePointer?
    private var locallyTerminatedCall: OpaquePointer?
    private var pendingIncomingPayload: VoIPIncomingPayload?
    private var deferredAction: DeferredNativeCallAction?
    private var incomingPushReceivedAt: Date?
    private var sipReadyQueuedAt: Date?
    private var audioSessionObserversInstalled = false
    private var callKitReportedForCurrentIncoming = false
    private var incomingInviteTimeoutTimer: Timer?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    private var lastEmittedSipReadyKey: String?
    private var speakerRouteRequestGeneration = 0
    private var selectedAudioRouteId: String?
    private var audioRouteSyncWorkItem: DispatchWorkItem?

    init(controller: FlutterViewController) {
        methodChannel = FlutterMethodChannel(
            name: Constants.methodChannelName,
            binaryMessenger: controller.binaryMessenger
        )
        eventChannel = FlutterEventChannel(
            name: Constants.eventChannelName,
            binaryMessenger: controller.binaryMessenger
        )
        snapshot = IOSNativeSipManager.loadSnapshot(from: UserDefaults.standard)

        super.init()

        eventChannel.setStreamHandler(self)
        methodChannel.setMethodCallHandler(handleMethodCall)
        if CallKitAvailabilityPolicy.isAvailable {
            voipPushManager.delegate = self
            callKitManager?.delegate = self
        }
    }

    deinit {
        incomingInviteTimeoutTimer?.invalidate()
        audioRouteSyncWorkItem?.cancel()
        if Thread.isMainThread {
            UIDevice.current.isProximityMonitoringEnabled = false
        } else {
            DispatchQueue.main.async {
                UIDevice.current.isProximityMonitoringEnabled = false
            }
        }
        teardownAudioSessionObservers()
        teardownLinphoneCore()
    }

    func initializeRuntimeIfNeeded() {
        guard !initialized else { return }
        initialized = true
        updateAppVisibility(isForeground: UIApplication.shared.applicationState == .active)
        if CallKitAvailabilityPolicy.isAvailable {
            voipPushManager.start()
        } else {
            defaults.removeObject(forKey: Constants.voipTokenKey)
            appendDiagnosticLog("callkit_disabled", [
                "reason": "china_storefront_or_region",
            ])
        }
        setupAudioSessionObserversIfNeeded()
        _ = restoreRegistrationIfNeeded(reason: "runtime-init", emitRegisteringEvent: false)
        appendDiagnosticLog("runtime_ready", [
            "platform": "ios",
        ])
        emit([
            "type": "native",
            "state": "ready",
            "platform": "ios",
        ])

        if let token = defaults.string(forKey: Constants.voipTokenKey), !token.isEmpty {
            emitPushTokenEvent(token: token)
        }
    }

    func updateAppVisibility(isForeground: Bool) {
        snapshot.appForeground = isForeground
        appendDiagnosticLog("app_visibility", [
            "foreground": isForeground ? "true" : "false",
            "call_state": snapshot.callState,
        ])
        if snapshot.persistentEnabled &&
            snapshot.callState != "incoming" &&
            snapshot.callState != "calling" &&
            snapshot.callState != "ringing" &&
            snapshot.callState != "in_call" {
            _ = restoreRegistrationIfNeeded(reason: isForeground ? "app-foreground" : "app-background",
                                            emitRegisteringEvent: false)
        }
        if !isForeground,
           snapshot.callState == "incoming",
           !callKitReportedForCurrentIncoming,
           let payload = pendingIncomingPayload {
            reportIncomingCallToSystemIfNeeded(payload: payload)
        }
        persistSnapshot()
        emit([
            "type": "app_visibility",
            "appForeground": isForeground,
            "callState": snapshot.callState,
            "remoteIdentity": snapshot.remoteIdentity ?? NSNull(),
        ])
    }

    func applicationDidEnterBackground() {
        updateAppVisibility(isForeground: false)
        beginBackgroundTransitionTask(reason: "app-background")
        if let core {
            linphone_core_enter_background(core)
            appendDiagnosticLog("linphone_enter_background", [:])
        }
        if snapshot.persistentEnabled {
            _ = restoreRegistrationIfNeeded(reason: "app-did-enter-background", emitRegisteringEvent: false)
        }
    }

    func applicationWillEnterForeground() {
        if let core {
            linphone_core_enter_foreground(core)
            appendDiagnosticLog("linphone_enter_foreground", [:])
        }
        endBackgroundTransitionTask(reason: "app-foreground")
        updateAppVisibility(isForeground: true)
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initializeRuntimeIfNeeded()
            result(true)
        case "getStateSnapshot":
            result(snapshot.toFlutterDictionary())
        case "getVoipPushToken":
            result(defaults.string(forKey: Constants.voipTokenKey))
        case "getPendingCallActions":
            result(loadPendingCallActions().map { $0.toFlutterDictionary() })
        case "consumePendingCallUiRequest":
            // iOS delivers CallKit actions through the native delegate and
            // does not persist a separate Flutter UI request like Android.
            result(nil)
        case "consumePendingCallActions":
            let actions = loadPendingCallActions()
            savePendingCallActions([])
            result(actions.map { $0.toFlutterDictionary() })
        case "getDiagnosticLogs":
            result(loadDiagnosticLogs().map { $0.toFlutterDictionary() })
        case "clearDiagnosticLogs":
            clearDiagnosticLogs()
            result(true)
        case "appendDiagnosticLog":
            guard
                let args = call.arguments as? [String: Any],
                let event = args["event"] as? String
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "Diagnostic event is required", details: nil))
                return
            }
            let details = (args["details"] as? [String: Any])?.reduce(into: [String: String]()) { result, item in
                result[item.key] = "\(item.value)"
            } ?? [:]
            appendDiagnosticLog(event, details)
            result(true)
        case "simulateIncomingCall":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Arguments are required", details: nil))
                return
            }
            let payload = VoIPIncomingPayload(
                issuedAt: nil,
                eventType: "incoming_call",
                uuid: UUID(uuidString: args["callUUID"] as? String ?? "") ?? UUID(),
                callId: args["callId"] as? String,
                handle: ((args["handle"] as? String) ?? "Unknown").trimmingCharacters(in: .whitespacesAndNewlines),
                callerName: args["callerName"] as? String,
                hasVideo: args["hasVideo"] as? Bool ?? false,
                fromUri: args["fromUri"] as? String,
                toUri: args["toUri"] as? String,
                sipUri: args["sipUri"] as? String,
                bridgeUri: args["bridgeUri"] as? String
            )
            reportIncomingCall(payload: payload)
            result(true)
        case "register":
            guard
                let args = call.arguments as? [String: Any],
                let config = NativeSipRegistrationConfig.from(arguments: args)
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid registration config", details: nil))
                return
            }
            initializeRuntimeIfNeeded()
            result(applyRegistrationConfig(config, emitRegisteringEvent: true))
        case "restoreRegistrationIfNeeded":
            initializeRuntimeIfNeeded()
            result(restoreRegistrationIfNeeded(reason: "flutter-request", emitRegisteringEvent: false))
        case "unregister":
            clearPersistedRegistrationConfig()
            result(unregister())
        case "makeCall":
            guard let args = call.arguments as? [String: Any], let target = args["target"] as? String else {
                result(false)
                return
            }
            result(makeCall(target: target, hasVideo: args["hasVideo"] as? Bool ?? false))
        case "acceptCall":
            // Answer is never allowed to restart REGISTER or create a new outgoing
            // call. If INVITE is late, acceptCall stores a deferred answer and the
            // Linphone incoming callback applies it immediately.
            result(acceptCall(reason: "flutter"))
        case "declineCall":
            result(declineCall())
        case "hangup":
            result(hangup(reason: "flutter"))
        case "sendDtmf":
            guard let args = call.arguments as? [String: Any], let tone = args["tone"] as? String else {
                result(false)
                return
            }
            result(sendDtmf(tone))
        case "setMuted":
            guard let args = call.arguments as? [String: Any], let muted = args["muted"] as? Bool else {
                result(false)
                return
            }
            result(setMuted(muted))
        case "setSpeaker":
            guard let args = call.arguments as? [String: Any], let speakerOn = args["speakerOn"] as? Bool else {
                result(false)
                return
            }
            result(setSpeaker(enabled: speakerOn))
        case "getAudioRoutes":
            result(availableAudioRoutes())
        case "setAudioRoute":
            guard
                let args = call.arguments as? [String: Any],
                let deviceId = args["deviceId"] as? String
            else {
                result(false)
                return
            }
            result(setAudioRoute(deviceId: deviceId))
        case "reportCallConnected":
            guard let uuid = resolvedCallUUID(from: call.arguments as? [String: Any]) else {
                result(false)
                return
            }
            callKitManager?.reportCallConnected(callUUID: uuid)
            snapshot.callUUID = uuid.uuidString
            snapshot.callState = "in_call"
            snapshot.message = "Call connected"
            persistSnapshot()
            emitCallEvent(state: "in_call", callId: snapshot.callId, message: "Call connected")
            result(true)
        case "reportCallEnded":
            guard let uuid = resolvedCallUUID(from: call.arguments as? [String: Any]) else {
                result(false)
                return
            }
            let reason = callEndedReason(from: (call.arguments as? [String: Any])?["reason"] as? String)
            callKitManager?.reportCallEnded(callUUID: uuid, reason: reason)
            handleCallEnded(reason: reason, callUUID: uuid, remoteIdentity: snapshot.remoteIdentity)
            result(true)
        case "endSystemCall":
            guard let uuid = resolvedCallUUID(from: call.arguments as? [String: Any]) else {
                result(false)
                return
            }
            guard let callKitManager else {
                result(true)
                return
            }
            callKitManager.requestEndCall(callUUID: uuid) { error in
                if let error {
                    result(FlutterError(code: "CALLKIT_END_FAILED", message: error.localizedDescription, details: nil))
                } else {
                    result(true)
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func ensureLinphoneCore() -> Bool {
        if core != nil {
            return true
        }

        let factory = linphone_factory_get()
        guard factory != nil else {
            snapshot.registrationState = "failed"
            snapshot.message = "Linphone factory is unavailable"
            persistSnapshot()
            return false
        }

        let paths = linphonePaths()
        do {
            try FileManager.default.createDirectory(at: paths.base, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: paths.cache, withIntermediateDirectories: true)
        } catch {
            snapshot.registrationState = "failed"
            snapshot.message = "Failed to prepare Linphone directories: \(error.localizedDescription)"
            persistSnapshot()
            return false
        }

        let configPath = paths.config.path
        guard let createdCore = linphone_factory_create_core_3(factory, configPath, nil, nil) else {
            snapshot.registrationState = "failed"
            snapshot.message = "Failed to create Linphone core"
            persistSnapshot()
            return false
        }

        core = createdCore
        linphone_core_set_user_data(createdCore, Unmanaged.passUnretained(self).toOpaque())
        linphone_core_enable_auto_iterate(createdCore, 1)
        linphone_core_enable_native_ringing(createdCore, 1)

        let callbacks = linphone_factory_create_core_cbs(factory)
        coreCallbacks = callbacks
        linphone_core_cbs_set_call_state_changed(callbacks, nativeSipCallStateChanged)
        linphone_core_cbs_set_account_registration_state_changed(callbacks, nativeSipAccountRegistrationStateChanged)
        linphone_core_add_callbacks(createdCore, callbacks)

        let startStatus = linphone_core_start(createdCore)
        guard startStatus == 0 else {
            snapshot.registrationState = "failed"
            snapshot.message = "Failed to start Linphone core (\(startStatus))"
            persistSnapshot()
            return false
        }

        return true
    }

    private func teardownLinphoneCore() {
        guard let core else { return }
        if let callbacks = coreCallbacks {
            linphone_core_remove_callbacks(core, callbacks)
        }
        linphone_core_stop(core)
        self.core = nil
        coreCallbacks = nil
        account = nil
        currentCall = nil
    }

    private func applyRegistrationConfig(
        _ config: NativeSipRegistrationConfig,
        emitRegisteringEvent: Bool
    ) -> Bool {
        // Начинаем регистрацию с чистого core, чтобы не переиспользовать
        // устаревшие auth/account данные от прошлых попыток.
        teardownLinphoneCore()

        guard ensureLinphoneCore(), let core else {
            emitRegistrationEvent(state: "failed", message: snapshot.message ?? "Linphone core unavailable")
            return false
        }

        if let existingAccount = account {
            linphone_core_remove_account(core, existingAccount)
            account = nil
        }
        linphone_core_clear_accounts(core)

        let factory = linphone_factory_get()

        let identityString = buildIdentityUri(login: config.login, server: config.server)
        let serverString = buildServerUri(server: config.server, port: config.port, transport: config.transport)

        guard
            let identityAddress = linphone_factory_create_address(factory, identityString),
            let serverAddress = linphone_factory_create_address(factory, serverString),
            let params = linphone_core_create_account_params(core)
        else {
            snapshot.registrationState = "failed"
            snapshot.message = "Failed to create Linphone addresses"
            persistSnapshot()
            emitRegistrationEvent(state: "failed", message: snapshot.message)
            return false
        }

        linphone_account_params_set_identity_address(params, identityAddress)
        linphone_account_params_set_server_address(params, serverAddress)
        linphone_account_params_set_transport(params, transportType(for: config.transport))
        linphone_account_params_enable_register(params, 1)
        linphone_account_params_set_expires(params, 300)
        linphone_account_params_set_push_notification_allowed(params, 1)
        linphone_account_params_set_remote_push_notification_allowed(params, 1)
        applyPushNotificationConfig(to: params, reason: "registration")
        linphone_account_params_enable_outbound_proxy(params, 1)

        guard let createdAccount = linphone_core_create_account(core, params) else {
            linphone_address_unref(identityAddress)
            linphone_address_unref(serverAddress)
            linphone_account_params_unref(params)
            snapshot.registrationState = "failed"
            snapshot.message = "Failed to create Linphone account"
            persistSnapshot()
            emitRegistrationEvent(state: "failed", message: snapshot.message)
            return false
        }

        if let authInfo = linphone_factory_create_auth_info(
            factory,
            config.authUser,
            nil,
            config.password,
            nil,
            nil,
            config.server
        ) {
            linphone_core_add_auth_info(core, authInfo)
            linphone_auth_info_unref(authInfo)
        }

        let addStatus = linphone_core_add_account(core, createdAccount)
        guard addStatus == 0 else {
            linphone_address_unref(identityAddress)
            linphone_address_unref(serverAddress)
            linphone_account_params_unref(params)
            linphone_account_unref(createdAccount)
            snapshot.registrationState = "failed"
            snapshot.message = "Failed to add Linphone account (\(addStatus))"
            persistSnapshot()
            emitRegistrationEvent(state: "failed", message: snapshot.message)
            return false
        }

        linphone_core_set_default_account(core, createdAccount)

        account = createdAccount
        snapshot.persistentEnabled = true
        snapshot.registrationState = "registering"
        snapshot.message = "Registration in progress"
        persistRegistrationConfig(config)
        persistSnapshot()

        if emitRegisteringEvent {
            emitRegistrationEvent(state: "registering", message: "Registration in progress")
        }

        linphone_address_unref(identityAddress)
        linphone_address_unref(serverAddress)
        linphone_account_params_unref(params)
        return true
    }

    private func applyPushNotificationConfig(to params: OpaquePointer, reason: String) {
        guard let pushConfig = linphone_push_notification_config_new() else {
            appendDiagnosticLog("sip_push_config_missing", [
                "reason": reason,
                "stage": "create_config_failed",
            ])
            return
        }

        let provider = NativeSipPushConfiguration.linphoneProvider
        let bundleIdentifier = NativeSipPushConfiguration.bundleIdentifier
        let token = defaults.string(forKey: Constants.voipTokenKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        linphone_push_notification_config_set_provider(pushConfig, provider)
        linphone_push_notification_config_set_team_id(pushConfig, NativeSipPushConfiguration.appleTeamId)
        linphone_push_notification_config_set_bundle_identifier(pushConfig, bundleIdentifier)
        linphone_push_notification_config_set_call_str(pushConfig, "IC_MSG")
        linphone_push_notification_config_set_remote_push_interval(pushConfig, "5")

        if !token.isEmpty {
            linphone_push_notification_config_set_voip_token(pushConfig, token)
        }

        linphone_account_params_set_push_notification_config(params, pushConfig)
        linphone_push_notification_config_unref(pushConfig)

        appendDiagnosticLog("sip_push_config_applied", [
            "reason": reason,
            "provider": provider,
            "bundle_id": bundleIdentifier,
            "team_id": NativeSipPushConfiguration.appleTeamId,
            "voip_token": token.isEmpty ? "missing" : "present",
        ])
    }

    private func refreshAccountPushNotificationConfig(reason: String) -> Bool {
        guard let existingAccount = account else { return false }
        guard let clonedParams = linphone_account_params_clone(linphone_account_get_params(existingAccount)) else {
            appendDiagnosticLog("sip_push_config_missing", [
                "reason": reason,
                "stage": "clone_params_failed",
            ])
            return false
        }

        linphone_account_params_set_push_notification_allowed(clonedParams, 1)
        linphone_account_params_set_remote_push_notification_allowed(clonedParams, 1)
        applyPushNotificationConfig(to: clonedParams, reason: reason)

        let status = linphone_account_set_params(existingAccount, clonedParams)
        linphone_account_params_unref(clonedParams)

        guard status == 0 else {
            appendDiagnosticLog("sip_push_config_failed", [
                "reason": reason,
                "status": "\(status)",
            ])
            return false
        }

        linphone_account_refresh_register(existingAccount)
        appendDiagnosticLog("sip_push_config_refresh", [
            "reason": reason,
        ])
        return true
    }

    private func refreshRegistrationIfPossible(reason: String, emitRegisteringEvent: Bool) -> Bool {
        guard snapshot.persistentEnabled, loadPersistedRegistrationConfig() != nil else {
            return false
        }

        guard let account else {
            return false
        }

        if linphone_account_get_state(account) != LinphoneRegistrationOk {
            return false
        }

        snapshot.registrationState = "registering"
        snapshot.message = "Registration refreshing"
        persistSnapshot()
        appendDiagnosticLog("sip_register_refresh_requested", [
            "reason": reason,
        ])
        if emitRegisteringEvent {
            emitRegistrationEvent(state: "registering", message: snapshot.message)
        }
        linphone_account_refresh_register(account)
        return true
    }

    private func restoreRegistrationIfNeeded(reason: String, emitRegisteringEvent: Bool) -> Bool {
        guard snapshot.persistentEnabled, let config = loadPersistedRegistrationConfig() else {
            return false
        }

        if let account, linphone_account_get_state(account) == LinphoneRegistrationOk {
            return true
        }

        return applyRegistrationConfig(config, emitRegisteringEvent: emitRegisteringEvent)
    }

    private func unregister() -> Bool {
        guard ensureLinphoneCore(), let core else {
            return false
        }

        if let existingAccount = account {
            let params = linphone_account_params_clone(linphone_account_get_params(existingAccount))
            linphone_account_params_enable_register(params, 0)
            linphone_account_set_params(existingAccount, params)
            linphone_account_params_unref(params)
            linphone_account_refresh_register(existingAccount)
            linphone_core_remove_account(core, existingAccount)
            account = nil
        }

        linphone_core_clear_accounts(core)
        snapshot.registrationState = "disconnected"
        snapshot.callState = "idle"
        snapshot.message = "Unregistration done"
        snapshot.persistentEnabled = false
        snapshot.remoteIdentity = nil
        snapshot.callUUID = nil
        snapshot.callId = nil
        snapshot.muted = false
        snapshot.speakerOn = false
        selectedAudioRouteId = nil
        persistSnapshot()
        emitRegistrationEvent(state: "disconnected", message: "Unregistration done")
        emitCallEvent(state: "ended", message: "Unregistration done")
        return true
    }

    private func makeCall(target: String, hasVideo: Bool) -> Bool {
        guard ensureLinphoneCore(), let core else {
            return false
        }

        guard let address = linphone_factory_create_address(linphone_factory_get(), target) else {
            emitCallEvent(state: "failed", message: "Invalid target address")
            return false
        }

        guard let params = linphone_core_create_call_params(core, nil) else {
            linphone_address_unref(address)
            emitCallEvent(state: "failed", message: "Failed to create call params")
            return false
        }

        linphone_call_params_enable_video(params, hasVideo ? 1 : 0)

        let call = linphone_core_invite_address_with_params(core, address, params)
        linphone_call_params_unref(params)
        linphone_address_unref(address)

        guard let call else {
            emitCallEvent(state: "failed", message: "Failed to start outgoing call")
            return false
        }

        currentCall = call
        snapshot.callState = "calling"
        // Каждый новый исходящий звонок стартует с обычного разговорного маршрута.
        // Это не даёт старому speaker-state из прошлого звонка залипать в UI.
        selectedAudioRouteId = nil
        snapshot.speakerOn = false
        snapshot.remoteIdentity = target
        snapshot.message = "Outgoing call started"
        snapshot.callId = callId(from: call) ?? snapshot.callId
        persistSnapshot()
        configureAudioSessionForCallIfNeeded()
        emitCallEvent(state: "calling", remoteIdentity: target, callId: snapshot.callId, message: snapshot.message)
        return true
    }

    private func acceptCall(reason: String) -> Bool {
        if snapshot.callState == "in_call" {
            appendDiagnosticLog("answer_ignored_already_connected", [
                "call_uuid": snapshot.callUUID ?? "",
                "call_id": snapshot.callId ?? "",
                "reason": reason,
            ])
            return true
        }

        let call = resolveIncomingCallForAction()
        appendDiagnosticLog("[VOIP] ANSWER_REQUESTED", [
            "call_uuid": snapshot.callUUID ?? "",
            "call_id": snapshot.callId ?? pendingIncomingPayload?.callId ?? "",
            "sip_call_id": snapshot.sipCallId ?? "",
            "has_invite": call == nil ? "false" : "true",
            "reason": reason,
        ])

        guard let call else {
            appendDiagnosticLog("answer_requested_no_invite", [
                "call_uuid": snapshot.callUUID ?? "",
                "call_id": snapshot.callId ?? "",
                "call_state": snapshot.callState,
                "has_pending_payload": pendingIncomingPayload == nil ? "false" : "true",
                "has_current_call": currentCall == nil ? "false" : "true",
                "account_state": currentAccountRegistrationStateString(),
            ])
            appendDiagnosticLog("[VOIP] ANSWER_DEFERRED_WAITING_INVITE", [
                "call_uuid": snapshot.callUUID ?? "",
                "call_id": snapshot.callId ?? pendingIncomingPayload?.callId ?? "",
                "sip_call_id": snapshot.sipCallId ?? "",
                "reason": reason,
            ])
            deferredAction = .answer
            snapshot.callState = "ringing"
            snapshot.message = "Waiting for SIP INVITE"
            persistSnapshot()
            emitCallEvent(
                state: "ringing",
                remoteIdentity: snapshot.remoteIdentity,
                callUUID: snapshot.callUUID,
                callId: snapshot.callId,
                message: snapshot.message,
                extra: pendingIncomingPayload?.toFlutterDictionary() ?? [:]
            )
            return true
        }

        guard let params = core.flatMap({ linphone_core_create_call_params($0, call) }) else {
            let status = linphone_call_accept(call)
            appendDiagnosticLog("answer_attached", [
                "call_id": snapshot.callId ?? pendingIncomingPayload?.callId ?? "",
                "sip_call_id": callId(from: call) ?? snapshot.sipCallId ?? "",
                "status": "\(status)",
                "mode": "default_params",
            ])
            appendDiagnosticLog("[VOIP] ANSWER_ATTACHED", [
                "call_id": snapshot.callId ?? pendingIncomingPayload?.callId ?? "",
                "sip_call_id": callId(from: call) ?? snapshot.sipCallId ?? "",
                "call_uuid": snapshot.callUUID ?? pendingIncomingPayload?.uuid.uuidString ?? "",
                "status": "\(status)",
                "mode": "default_params",
            ])
            return status == 0
        }

        linphone_call_params_enable_video(params, 0)
        let status = linphone_call_accept_with_params(call, params)
        linphone_call_params_unref(params)
        appendDiagnosticLog("answer_attached", [
            "call_id": snapshot.callId ?? pendingIncomingPayload?.callId ?? "",
            "sip_call_id": callId(from: call) ?? snapshot.sipCallId ?? "",
            "status": "\(status)",
            "mode": "custom_params",
        ])
        appendDiagnosticLog("[VOIP] ANSWER_ATTACHED", [
            "call_id": snapshot.callId ?? pendingIncomingPayload?.callId ?? "",
            "sip_call_id": callId(from: call) ?? snapshot.sipCallId ?? "",
            "call_uuid": snapshot.callUUID ?? pendingIncomingPayload?.uuid.uuidString ?? "",
            "status": "\(status)",
            "mode": "custom_params",
        ])
        return status == 0
    }

    private func declineCall() -> Bool {
        if let call = resolveIncomingCallForAction() {
            return linphone_call_decline(call, LinphoneReasonDeclined) == 0
        }

        deferredAction = .decline
        return false
    }

    private func hangup(reason: String) -> Bool {
        let call = resolveCurrentCallForAction()
        let endedCallUUID = snapshot.callUUID
        let endedCallId = snapshot.callId
        let endedSipCallId = call.flatMap(callId(from:)) ?? snapshot.sipCallId
        let endedRemoteIdentity = call.flatMap(remoteIdentityString(from:)) ?? snapshot.remoteIdentity

        appendDiagnosticLog("[VOIP] HANGUP_REQUESTED", [
            "reason": reason,
            "call_uuid": endedCallUUID ?? "",
            "call_id": endedCallId ?? "",
            "sip_call_id": endedSipCallId ?? "",
            "has_call": call == nil ? "false" : "true",
            "call_state": snapshot.callState,
        ])

        if let call {
            locallyTerminatedCall = call
            let status = linphone_call_terminate(call)
            appendDiagnosticLog("hangup_terminate_result", [
                "reason": reason,
                "call_id": endedCallId ?? "",
                "sip_call_id": endedSipCallId ?? "",
                "status": "\(status)",
            ])
            guard status == 0 else {
                locallyTerminatedCall = nil
                return false
            }
        } else {
            let hasVisibleCall = snapshot.callState == "incoming" ||
                snapshot.callState == "calling" ||
                snapshot.callState == "ringing" ||
                snapshot.callState == "in_call"
            guard hasVisibleCall else {
                return false
            }
        }

        // Do not wait for PBX to echo End/Released. A local hangup must close
        // the app and CallKit state immediately after BYE was queued.
        cancelIncomingInviteTimeout()
        currentCall = nil
        deferredAction = nil
        pendingIncomingPayload = nil
        incomingPushReceivedAt = nil
        sipReadyQueuedAt = nil
        snapshot.callUUID = nil
        snapshot.callId = nil
        snapshot.sipCallId = nil
        snapshot.callState = "ended"
        snapshot.remoteIdentity = nil
        snapshot.message = "Call ended locally"
        snapshot.muted = false
        snapshot.speakerOn = false
        selectedAudioRouteId = nil
        persistSnapshot()

        if let endedCallUUID, let uuid = UUID(uuidString: endedCallUUID) {
            callKitManager?.reportCallEnded(callUUID: uuid, reason: .remoteEnded)
        }

        appendDiagnosticLog("[VOIP] LOCAL_HANGUP_APPLIED", [
            "reason": reason,
            "call_uuid": endedCallUUID ?? "",
            "call_id": endedCallId ?? "",
            "sip_call_id": endedSipCallId ?? "",
        ])
        emitCallEvent(
            state: "ended",
            remoteIdentity: endedRemoteIdentity,
            callUUID: endedCallUUID,
            callId: endedCallId,
            message: snapshot.message,
            extra: ["sipCallId": endedSipCallId as Any? ?? NSNull()]
        )
        return true
    }

    private func startBridgeCallFromPushPayload(_ payload: VoIPIncomingPayload?, reason: String) -> Bool {
        guard let rawBridgeUri = payload?.bridgeUri?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawBridgeUri.isEmpty else {
            appendDiagnosticLog("callkit_answer_waiting_for_invite", [
                "reason": reason,
                "call_uuid": payload?.uuid.uuidString ?? snapshot.callUUID ?? "",
                "call_id": payload?.callId ?? snapshot.callId ?? "",
                "bridge_uri": "missing",
                "sip_uri": payload?.sipUri ?? "",
            ])
            return false
        }

        let target = rawBridgeUri.lowercased().hasPrefix("sip:")
            ? rawBridgeUri
            : "sip:\(rawBridgeUri)"

        appendDiagnosticLog("callkit_answer_bridge_call_start", [
            "reason": reason,
            "call_uuid": payload?.uuid.uuidString ?? snapshot.callUUID ?? "",
            "call_id": payload?.callId ?? snapshot.callId ?? "",
            "bridge_uri": target,
        ])

        return makeCall(target: target, hasVideo: payload?.hasVideo ?? false)
    }

    private func sendDtmf(_ tone: String) -> Bool {
        guard let call = resolveCurrentCallForAction() else {
            return false
        }

        let normalized = tone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let symbol = normalized.first else {
            return false
        }

        return normalized.withCString { cString in
            linphone_call_send_dtmfs(call, cString) == 0
        }
    }

    private func setMuted(_ muted: Bool) -> Bool {
        guard let call = resolveCurrentCallForAction() else {
            snapshot.muted = muted
            persistSnapshot()
            emitCallEvent(state: snapshot.callState, message: snapshot.message)
            return false
        }

        linphone_call_set_microphone_muted(call, muted ? 1 : 0)
        snapshot.muted = muted
        persistSnapshot()
        emitCallEvent(state: snapshot.callState, message: snapshot.message)
        return true
    }

    private func setSpeaker(enabled: Bool) -> Bool {
        speakerRouteRequestGeneration += 1
        let requestGeneration = speakerRouteRequestGeneration
        let previousSpeaker = snapshot.speakerOn
        selectedAudioRouteId = enabled ? "speaker" : nil
        snapshot.speakerOn = enabled
        persistSnapshot()
        appendDiagnosticLog("[VOIP] AUDIO_ROUTE_REQUESTED", [
            "speaker_on": enabled ? "true" : "false",
            "previous_speaker_on": previousSpeaker ? "true" : "false",
            "call_state": snapshot.callState,
            "generation": "\(requestGeneration)",
        ])
        emitCallEvent(state: snapshot.callState, message: snapshot.message)

        // Return to Flutter before Linphone/AVAudioSession rebuilds the route.
        // Applying it synchronously could leave the call controls unresponsive.
        DispatchQueue.main.async { [weak self] in
            self?.applySpeakerRoute(
                enabled: enabled,
                requestGeneration: requestGeneration
            )
        }
        return true
    }

    private func availableAudioRoutes() -> [[String: Any]] {
        let session = AVAudioSession.sharedInstance()
        let inputs = session.availableInputs ?? []
        let currentOutput = currentAudioOutputKind(route: session.currentRoute)
        var routes: [[String: Any]] = []

        if let bluetooth = inputs.first(where: { isBluetoothPort($0.portType) }) {
            routes.append([
                "id": "bluetooth",
                "type": "bluetooth",
                "name": bluetooth.portName.isEmpty ? "Bluetooth-наушники" : bluetooth.portName,
                "selected": currentOutput == "bluetooth",
            ])
        }

        if let headset = inputs.first(where: { isWiredHeadsetPort($0.portType) }) {
            routes.append([
                "id": "headset",
                "type": "headset",
                "name": headset.portName.isEmpty ? "Проводные наушники" : headset.portName,
                "selected": currentOutput == "headphones",
            ])
        }

        if UIDevice.current.userInterfaceIdiom == .phone {
            routes.append([
                "id": "earpiece",
                "type": "earpiece",
                "name": "iPhone",
                "selected": currentOutput == "earpiece",
            ])
        }

        routes.append([
            "id": "speaker",
            "type": "speaker",
            "name": "Громкая связь",
            "selected": currentOutput == "speaker",
        ])
        return routes
    }

    private func setAudioRoute(deviceId: String) -> Bool {
        let routeId = deviceId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard ["bluetooth", "headset", "earpiece", "speaker"].contains(routeId) else {
            return false
        }
        guard availableAudioRoutes().contains(where: { ($0["id"] as? String) == routeId }) else {
            return false
        }

        speakerRouteRequestGeneration += 1
        let requestGeneration = speakerRouteRequestGeneration
        selectedAudioRouteId = routeId
        snapshot.speakerOn = routeId == "speaker"
        persistSnapshot()
        emitCallEvent(state: snapshot.callState, message: snapshot.message)
        appendDiagnosticLog("[VOIP] AUDIO_ROUTE_REQUESTED", [
            "route_id": routeId,
            "call_state": snapshot.callState,
            "generation": "\(requestGeneration)",
        ])

        DispatchQueue.main.async { [weak self] in
            self?.applyExplicitAudioRoute(
                routeId,
                requestGeneration: requestGeneration,
                reason: "user_selected"
            )
        }
        return true
    }

    private func applyExplicitAudioRoute(
        _ routeId: String,
        requestGeneration: Int,
        reason: String
    ) {
        guard requestGeneration == speakerRouteRequestGeneration else {
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth, .allowBluetoothA2DP]
            )
            try session.setActive(true, options: [])

            let preferredInput: AVAudioSessionPortDescription?
            switch routeId {
            case "bluetooth":
                preferredInput = session.availableInputs?.first {
                    isBluetoothPort($0.portType)
                }
            case "headset":
                preferredInput = session.availableInputs?.first {
                    isWiredHeadsetPort($0.portType)
                }
            case "earpiece", "speaker":
                preferredInput = session.availableInputs?.first {
                    $0.portType == .builtInMic
                }
            default:
                preferredInput = nil
            }

            if routeId == "bluetooth" || routeId == "headset" {
                guard let preferredInput else {
                    selectedAudioRouteId = nil
                    syncAudioRouteState(reason: "selected_route_unavailable")
                    return
                }
                try session.setPreferredInput(preferredInput)
            } else if let preferredInput {
                try session.setPreferredInput(preferredInput)
            }

            try session.overrideOutputAudioPort(routeId == "speaker" ? .speaker : .none)
            selectLinphoneAudioDevice(routeId: routeId, reason: reason)
            appendDiagnosticLog("[VOIP] AUDIO_ROUTE_APPLIED", [
                "route_id": routeId,
                "route": audioRouteDescription(session.currentRoute),
                "generation": "\(requestGeneration)",
            ])
            scheduleAudioRouteSync(reason: reason)
        } catch {
            appendDiagnosticLog("[VOIP] AUDIO_ROUTE_FAILED", [
                "route_id": routeId,
                "error": error.localizedDescription,
            ])
            syncAudioRouteState(reason: "explicit_route_failed")
        }
    }

    private func selectLinphoneAudioDevice(routeId: String, reason: String) {
        guard let call = resolveCurrentCallForAction(), let core else {
            return
        }

        let devices = linphone_core_get_audio_devices(core)
        var item = devices
        var selected: OpaquePointer?
        while let currentItem = item {
            let pointer = bctbx_list_get_data(currentItem)
            if let device = pointer.map({ OpaquePointer($0) }),
               audioDeviceMatchesRoute(
                   type: linphone_audio_device_get_type(device),
                   routeId: routeId
               ) {
                selected = device
                break
            }
            item = bctbx_list_next(currentItem)
        }

        guard let selected else {
            return
        }
        linphone_call_set_output_audio_device(call, selected)
        appendDiagnosticLog("audio_device_selected", [
            "reason": reason,
            "route_id": routeId,
            "device_type": audioDeviceTypeDescription(
                linphone_audio_device_get_type(selected)
            ),
        ])
    }

    private func audioDeviceMatchesRoute(
        type: LinphoneAudioDeviceType,
        routeId: String
    ) -> Bool {
        switch routeId {
        case "bluetooth":
            return type == LinphoneAudioDeviceTypeBluetooth
        case "headset":
            return type == LinphoneAudioDeviceTypeHeadset ||
                type == LinphoneAudioDeviceTypeHeadphones
        case "earpiece":
            return type == LinphoneAudioDeviceTypeEarpiece
        case "speaker":
            return type == LinphoneAudioDeviceTypeSpeaker
        default:
            return false
        }
    }

    private func isBluetoothPort(_ portType: AVAudioSession.Port) -> Bool {
        portType == .bluetoothHFP ||
            portType == .bluetoothA2DP ||
            portType == .bluetoothLE
    }

    private func isWiredHeadsetPort(_ portType: AVAudioSession.Port) -> Bool {
        portType == .headsetMic ||
            portType == .headphones ||
            portType == .usbAudio ||
            portType == .lineIn
    }

    private func applySpeakerRoute(enabled: Bool, requestGeneration: Int) {
        guard requestGeneration == speakerRouteRequestGeneration else {
            return
        }

        guard let call = resolveCurrentCallForAction(), let core else {
            configureAudioSessionForCallIfNeeded()
            emitAudioSessionEvent(state: "route_preference_updated", reason: "no_active_call")
            scheduleAudioRouteSync(reason: "speaker_request_no_active_call")
            return
        }

        let devices = linphone_core_get_audio_devices(core)
        var item = devices
        var selected: OpaquePointer?

        while let currentItem = item {
            let devicePointer = bctbx_list_get_data(currentItem)
            let device = devicePointer.map { OpaquePointer($0) }
            if let device {
                let type = linphone_audio_device_get_type(device)
                if enabled, type == LinphoneAudioDeviceTypeSpeaker {
                    selected = device
                    break
                }
                if !enabled {
                    selected = preferredNonSpeakerDevice(candidate: device, currentSelected: selected)
                }
            }
            item = bctbx_list_next(currentItem)
        }

        if let selected {
            linphone_call_set_output_audio_device(call, selected)
        } else {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.overrideOutputAudioPort(enabled ? .speaker : .none)
            } catch {
                appendDiagnosticLog("[VOIP] AUDIO_ROUTE_FAILED", [
                    "speaker_on": enabled ? "true" : "false",
                    "error": error.localizedDescription,
                ])
                syncAudioRouteState(reason: "speaker_request_failed")
                return
            }
        }

        appendDiagnosticLog("[VOIP] AUDIO_ROUTE_APPLIED", [
            "speaker_on": enabled ? "true" : "false",
            "route": audioRouteDescription(AVAudioSession.sharedInstance().currentRoute),
            "generation": "\(requestGeneration)",
        ])
        scheduleAudioRouteSync(
            reason: enabled ? "speaker_enabled" : "speaker_disabled"
        )
    }

    private func scheduleAudioRouteSync(reason: String) {
        audioRouteSyncWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.syncAudioRouteState(reason: reason)
        }
        audioRouteSyncWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }

    private func selectPreferredNonSpeakerAudioDevice(reason: String) {
        guard !snapshot.speakerOn,
              let call = resolveCurrentCallForAction(),
              let core else {
            return
        }

        let devices = linphone_core_get_audio_devices(core)
        var item = devices
        var selected: OpaquePointer?

        while let currentItem = item {
            let devicePointer = bctbx_list_get_data(currentItem)
            let device = devicePointer.map { OpaquePointer($0) }
            if let device {
                selected = preferredNonSpeakerDevice(
                    candidate: device,
                    currentSelected: selected
                )
            }
            item = bctbx_list_next(currentItem)
        }

        guard let selected else {
            return
        }

        linphone_call_set_output_audio_device(call, selected)
        appendDiagnosticLog("audio_device_selected", [
            "reason": reason,
            "device_type": audioDeviceTypeDescription(
                linphone_audio_device_get_type(selected)
            ),
            "route": audioRouteDescription(AVAudioSession.sharedInstance().currentRoute),
        ])
    }

    private func preferredNonSpeakerDevice(
        candidate: OpaquePointer,
        currentSelected: OpaquePointer?
    ) -> OpaquePointer? {
        let candidateType = linphone_audio_device_get_type(candidate)
        let candidatePriority = audioDevicePriority(type: candidateType)
        guard candidatePriority > 0 else {
            return currentSelected
        }

        guard let currentSelected else {
            return candidate
        }

        let currentType = linphone_audio_device_get_type(currentSelected)
        let currentPriority = audioDevicePriority(type: currentType)
        return candidatePriority > currentPriority ? candidate : currentSelected
    }

    private func audioDevicePriority(type: LinphoneAudioDeviceType) -> Int {
        switch type {
        case LinphoneAudioDeviceTypeBluetooth:
            return 4
        case LinphoneAudioDeviceTypeHeadset:
            return 3
        case LinphoneAudioDeviceTypeHeadphones:
            return 2
        case LinphoneAudioDeviceTypeEarpiece:
            return 1
        default:
            return 0
        }
    }

    private func audioDeviceTypeDescription(_ type: LinphoneAudioDeviceType) -> String {
        switch type {
        case LinphoneAudioDeviceTypeBluetooth:
            return "bluetooth"
        case LinphoneAudioDeviceTypeHeadset:
            return "headset"
        case LinphoneAudioDeviceTypeHeadphones:
            return "headphones"
        case LinphoneAudioDeviceTypeEarpiece:
            return "earpiece"
        case LinphoneAudioDeviceTypeSpeaker:
            return "speaker"
        case LinphoneAudioDeviceTypeMicrophone:
            return "microphone"
        default:
            return "unknown"
        }
    }

    private func setupAudioSessionObserversIfNeeded() {
        guard !audioSessionObserversInstalled else { return }
        audioSessionObserversInstalled = true
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleAudioRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    private func teardownAudioSessionObservers() {
        guard audioSessionObserversInstalled else { return }
        audioSessionObserversInstalled = false
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    }

    @objc
    private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: rawType) else {
            return
        }

        switch interruptionType {
        case .began:
            emitAudioSessionEvent(state: "interruption_began")
        case .ended:
            configureAudioSessionForCallIfNeeded()
            selectPreferredNonSpeakerAudioDevice(reason: "interruption_ended")
            syncAudioRouteState(reason: "interruption_ended")
            emitAudioSessionEvent(state: "interruption_ended")
        @unknown default:
            emitAudioSessionEvent(state: "interruption_unknown")
        }
    }

    @objc
    private func handleAudioRouteChange(_ notification: Notification) {
        let reasonDescription: String
        if let userInfo = notification.userInfo,
           let rawReason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
           let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason) {
            reasonDescription = audioRouteChangeReasonDescription(reason)
        } else {
            reasonDescription = "unknown"
        }

        appendDiagnosticLog("audio_route_changed", [
            "reason": reasonDescription,
            "speaker_requested": snapshot.speakerOn ? "true" : "false",
            "route": audioRouteDescription(AVAudioSession.sharedInstance().currentRoute),
        ])

        // Do not reconfigure AVAudioSession from its own route-change callback.
        // setCategory/setActive/override can emit another notification and form
        // a feedback loop that blocks the application.
        if reasonDescription == "new_device_available" ||
            reasonDescription == "old_device_unavailable" {
            if let selectedAudioRouteId,
               !availableAudioRoutes().contains(where: {
                   ($0["id"] as? String) == selectedAudioRouteId
               }) {
                self.selectedAudioRouteId = nil
                snapshot.speakerOn = false
                persistSnapshot()
            }
            if selectedAudioRouteId == nil && !snapshot.speakerOn {
                selectPreferredNonSpeakerAudioDevice(reason: reasonDescription)
            }
        }
        scheduleAudioRouteSync(reason: reasonDescription)
    }

    private func configureAudioSessionForCallIfNeeded() {
        guard snapshot.callState == "calling" ||
                snapshot.callState == "ringing" ||
                snapshot.callState == "incoming" ||
                snapshot.callState == "in_call" else {
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            print("IOSNativeSipManager configureAudioSessionForCallIfNeeded -> callState=\(snapshot.callState), speakerOn=\(snapshot.speakerOn)")
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth, .allowBluetoothA2DP]
            )
            try session.setActive(true, options: [])
            if selectedAudioRouteId == "speaker" || snapshot.speakerOn {
                try session.overrideOutputAudioPort(.speaker)
            } else if let selectedAudioRouteId {
                try session.overrideOutputAudioPort(.none)
                let requestGeneration = speakerRouteRequestGeneration
                DispatchQueue.main.async { [weak self] in
                    self?.applyExplicitAudioRoute(
                        selectedAudioRouteId,
                        requestGeneration: requestGeneration,
                        reason: "audio_session_configured"
                    )
                }
            } else {
                try session.overrideOutputAudioPort(.none)
                selectPreferredNonSpeakerAudioDevice(reason: "audio_session_configured")
            }
        } catch {
            emitAudioSessionEvent(state: "configuration_failed", reason: error.localizedDescription)
        }
    }

    private func syncAudioRouteState(reason: String) {
        let session = AVAudioSession.sharedInstance()
        let route = session.currentRoute
        let outputKind = currentAudioOutputKind(route: route)
        let isCallActive =
            snapshot.callState == "calling" ||
            snapshot.callState == "ringing" ||
            snapshot.callState == "incoming" ||
            snapshot.callState == "in_call"
        print("IOSNativeSipManager syncAudioRouteState -> reason=\(reason), callState=\(snapshot.callState), previousSpeaker=\(snapshot.speakerOn), output=\(outputKind), route=\(audioRouteDescription(route))")
        snapshot.speakerOn = isCallActive && outputKind == "speaker"
        persistSnapshot()
        emitAudioSessionEvent(
            state: "route_changed",
            reason: reason,
            output: outputKind,
            route: audioRouteDescription(route)
        )
        emitCallEvent(state: snapshot.callState, message: snapshot.message)
    }

    private func currentAudioOutputKind(route: AVAudioSessionRouteDescription) -> String {
        let outputs = route.outputs.map(\.portType)
        if outputs.contains(.builtInSpeaker) {
            return "speaker"
        }
        if outputs.contains(.bluetoothA2DP) ||
            outputs.contains(.bluetoothHFP) ||
            outputs.contains(.bluetoothLE) {
            return "bluetooth"
        }
        if outputs.contains(.headphones) ||
            outputs.contains(.headsetMic) {
            return "headphones"
        }
        if outputs.contains(.builtInReceiver) {
            return "earpiece"
        }
        return outputs.first?.rawValue ?? "unknown"
    }

    private func updateProximityMonitoring(callState: String, reason: String) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.updateProximityMonitoring(callState: callState, reason: reason)
            }
            return
        }

        let output = currentAudioOutputKind(
            route: AVAudioSession.sharedInstance().currentRoute
        )
        let shouldEnable = callState == "in_call" && output == "earpiece"
        guard UIDevice.current.isProximityMonitoringEnabled != shouldEnable else {
            return
        }

        UIDevice.current.isProximityMonitoringEnabled = shouldEnable
        appendDiagnosticLog("proximity_monitoring", [
            "enabled": shouldEnable ? "true" : "false",
            "reason": reason,
            "call_state": callState,
            "output": output,
        ])
    }

    private func audioRouteDescription(_ route: AVAudioSessionRouteDescription) -> String {
        route.outputs
            .map { "\($0.portType.rawValue):\($0.portName)" }
            .joined(separator: ",")
    }

    private func audioRouteChangeReasonDescription(_ reason: AVAudioSession.RouteChangeReason) -> String {
        switch reason {
        case .newDeviceAvailable:
            return "new_device_available"
        case .oldDeviceUnavailable:
            return "old_device_unavailable"
        case .categoryChange:
            return "category_change"
        case .override:
            return "override"
        case .wakeFromSleep:
            return "wake_from_sleep"
        case .noSuitableRouteForCategory:
            return "no_suitable_route"
        case .routeConfigurationChange:
            return "route_configuration_change"
        case .unknown:
            return "unknown"
        @unknown default:
            return "unknown"
        }
    }

    private func emitAudioSessionEvent(
        state: String,
        reason: String? = nil,
        output: String? = nil,
        route: String? = nil
    ) {
        emit([
            "type": "audio_session",
            "state": state,
            "reason": reason ?? NSNull(),
            "output": output ?? currentAudioOutputKind(route: AVAudioSession.sharedInstance().currentRoute),
            "route": route ?? audioRouteDescription(AVAudioSession.sharedInstance().currentRoute),
            "speakerOn": snapshot.speakerOn,
            "callState": snapshot.callState,
        ])
    }

    private func resolveIncomingCallForAction() -> OpaquePointer? {
        if let currentCall {
            let state = linphone_call_get_state(currentCall)
            if state == LinphoneCallStateIncomingReceived || state == LinphoneCallStatePushIncomingReceived {
                return currentCall
            }
        }
        if let core, linphone_core_is_incoming_invite_pending(core) != 0 {
            let call = linphone_core_get_current_call(core)
            currentCall = call
            return call
        }
        if let call = findIncomingCallInCore() {
            currentCall = call
            return call
        }
        return nil
    }

    private func findIncomingCallInCore() -> OpaquePointer? {
        guard let core else { return nil }

        let expectedCallIds = [
            snapshot.callId,
            pendingIncomingPayload?.callId,
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let expectedRemotes = [
            snapshot.remoteIdentity,
            pendingIncomingPayload?.handle,
            pendingIncomingPayload?.fromUri,
            pendingIncomingPayload?.sipUri,
        ]
            .compactMap(normalizedIdentityForMatching)
            .filter { !$0.isEmpty }

        var fallbackIncomingCall: OpaquePointer?
        var item = linphone_core_get_calls(core)

        while let currentItem = item {
            let callPointer = bctbx_list_get_data(currentItem)
            let call = callPointer.map { OpaquePointer($0) }

            if let call, isIncomingCallState(linphone_call_get_state(call)) {
                if fallbackIncomingCall == nil {
                    fallbackIncomingCall = call
                }

                if let callId = callId(from: call),
                   expectedCallIds.contains(where: { $0 == callId }) {
                    return call
                }

                if let remote = normalizedIdentityForMatching(remoteIdentityString(from: call)),
                   expectedRemotes.contains(remote) {
                    return call
                }
            }

            item = bctbx_list_next(currentItem).map { UnsafePointer($0) }
        }

        return fallbackIncomingCall
    }

    private func isIncomingCallState(_ state: LinphoneCallState) -> Bool {
        state == LinphoneCallStateIncomingReceived || state == LinphoneCallStatePushIncomingReceived
    }

    private func normalizedIdentityForMatching(_ value: String?) -> String? {
        guard var normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !normalized.isEmpty else {
            return nil
        }

        if normalized.lowercased().hasPrefix("sip:") {
            normalized = String(normalized.dropFirst(4))
        }
        if let semicolonIndex = normalized.firstIndex(of: ";") {
            normalized = String(normalized[..<semicolonIndex])
        }
        if let atIndex = normalized.firstIndex(of: "@") {
            normalized = String(normalized[..<atIndex])
        }

        normalized = normalized
            .replacingOccurrences(of: "+", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return normalized.isEmpty ? nil : normalized
    }

    private func resolveCurrentCallForAction() -> OpaquePointer? {
        if let currentCall {
            return currentCall
        }
        if let core {
            let call = linphone_core_get_current_call(core)
            currentCall = call
            return call
        }
        return nil
    }

    private func currentAccountRegistrationStateString() -> String {
        guard let account else { return "missing_account" }

        switch linphone_account_get_state(account) {
        case LinphoneRegistrationNone:
            return "none"
        case LinphoneRegistrationProgress:
            return "progress"
        case LinphoneRegistrationOk:
            return "ok"
        case LinphoneRegistrationCleared:
            return "cleared"
        case LinphoneRegistrationFailed:
            return "failed"
        case LinphoneRegistrationRefreshing:
            return "refreshing"
        default:
            return "unknown"
        }
    }

    fileprivate func handleLinphoneRegistrationStateChanged(
        account: OpaquePointer?,
        state: LinphoneRegistrationState,
        message: String?
    ) {
        if let account {
            self.account = account
        }

        switch state {
        case LinphoneRegistrationProgress, LinphoneRegistrationRefreshing:
            snapshot.registrationState = "registering"
            snapshot.message = message ?? "Registration in progress"
            snapshot.persistentEnabled = true
            appendDiagnosticLog("sip_register_start", [
                "message": snapshot.message ?? "",
            ])
            appendDiagnosticLog("[VOIP] REGISTRATION_IN_PROGRESS", [
                "message": snapshot.message ?? "",
                "call_id": snapshot.callId ?? pendingIncomingPayload?.callId ?? "",
                "call_uuid": snapshot.callUUID ?? pendingIncomingPayload?.uuid.uuidString ?? "",
            ])
            emitRegistrationEvent(state: "registering", message: snapshot.message)
        case LinphoneRegistrationOk:
            snapshot.registrationState = "registered"
            snapshot.message = message ?? "Registration successful"
            snapshot.persistentEnabled = true
            appendDiagnosticLog("sip_register_ok", [
                "message": snapshot.message ?? "",
            ])
            appendDiagnosticLog("[VOIP] REGISTRATION_SUCCESSFUL", [
                "message": snapshot.message ?? "",
                "call_id": snapshot.callId ?? pendingIncomingPayload?.callId ?? "",
                "call_uuid": snapshot.callUUID ?? pendingIncomingPayload?.uuid.uuidString ?? "",
            ])
            endBackgroundTransitionTask(reason: "registration-ok")
            emitRegistrationEvent(state: "registered", message: snapshot.message)
            emitSipReadyIfNeeded(reason: "registration-ok")
        case LinphoneRegistrationFailed:
            snapshot.registrationState = "failed"
            snapshot.message = message ?? "Registration failed"
            appendDiagnosticLog("sip_register_fail", [
                "message": snapshot.message ?? "",
            ])
            endBackgroundTransitionTask(reason: "registration-failed")
            emitRegistrationEvent(state: "failed", message: snapshot.message)
        case LinphoneRegistrationCleared:
            snapshot.registrationState = "disconnected"
            snapshot.message = message ?? "Unregistration done"
            endBackgroundTransitionTask(reason: "registration-cleared")
            emitRegistrationEvent(state: "disconnected", message: snapshot.message)
        default:
            snapshot.registrationState = "disconnected"
            snapshot.message = message
            endBackgroundTransitionTask(reason: "registration-disconnected")
            emitRegistrationEvent(state: "disconnected", message: snapshot.message)
        }

        persistSnapshot()
    }

    fileprivate func handleLinphoneCallStateChanged(
        call: OpaquePointer?,
        state: LinphoneCallState,
        message: String?
    ) {
        let previousCallState = snapshot.callState
        if let call {
            currentCall = call
        }

        let remoteIdentity = call.flatMap(remoteIdentityString(from:))
        let linphoneCallId = call.flatMap(callId(from:))
        if let linphoneCallId {
            // Test flow: keep Push/Linkedid call_id stable and store SIP Call-ID separately.
            // Previous behavior for quick rollback: snapshot.callId = linphoneCallId
            snapshot.sipCallId = linphoneCallId
            if snapshot.callId == nil && pendingIncomingPayload?.callId == nil {
                snapshot.callId = linphoneCallId
            }
        }
        if let remoteIdentity {
            snapshot.remoteIdentity = remoteIdentity
        }

        switch state {
        case LinphoneCallStateIncomingReceived, LinphoneCallStatePushIncomingReceived:
            locallyTerminatedCall = nil
            cancelIncomingInviteTimeout()
            let inviteReceivedAt = Date()
            let pushToInviteMilliseconds = incomingPushReceivedAt.map {
                max(0, Int(inviteReceivedAt.timeIntervalSince($0) * 1000))
            }
            let sipReadyToInviteMilliseconds = sipReadyQueuedAt.map {
                max(0, Int(inviteReceivedAt.timeIntervalSince($0) * 1000))
            }
            appendDiagnosticLog("invite_received", [
                "call_id": linphoneCallId ?? "",
                "push_call_id": snapshot.callId ?? pendingIncomingPayload?.callId ?? "",
                "remote_identity": remoteIdentity ?? "",
                "push_to_invite_ms": pushToInviteMilliseconds.map(String.init) ?? "",
                "sip_ready_to_invite_ms": sipReadyToInviteMilliseconds.map(String.init) ?? "",
            ])
            appendDiagnosticLog("[VOIP] INVITE_RECEIVED", [
                "call_id": snapshot.callId ?? pendingIncomingPayload?.callId ?? "",
                "sip_call_id": linphoneCallId ?? "",
                "remote_identity": remoteIdentity ?? "",
                "call_uuid": snapshot.callUUID ?? pendingIncomingPayload?.uuid.uuidString ?? "",
                "push_to_invite_ms": pushToInviteMilliseconds.map(String.init) ?? "",
                "sip_ready_to_invite_ms": sipReadyToInviteMilliseconds.map(String.init) ?? "",
            ])
            let invitePayload = VoIPIncomingPayload(
                issuedAt: pendingIncomingPayload?.issuedAt,
                eventType: "incoming_call",
                uuid: resolvedCallUUID(from: nil) ?? pendingIncomingPayload?.uuid ?? UUID(),
                // Test flow: preserve call_id from Push for backend mapping.
                // Previous behavior for quick rollback: callId: linphoneCallId ?? pendingIncomingPayload?.callId
                callId: pendingIncomingPayload?.callId ?? snapshot.callId ?? linphoneCallId,
                handle: remoteIdentity ?? pendingIncomingPayload?.handle ?? "Unknown",
                callerName: pendingIncomingPayload?.callerName,
                hasVideo: pendingIncomingPayload?.hasVideo ?? false,
                fromUri: pendingIncomingPayload?.fromUri ?? remoteIdentity,
                toUri: pendingIncomingPayload?.toUri,
                sipUri: pendingIncomingPayload?.sipUri ?? remoteIdentity,
                bridgeUri: pendingIncomingPayload?.bridgeUri
            )
            pendingIncomingPayload = invitePayload
            appendDiagnosticLog("[VOIP] INVITE_MATCHED", [
                "call_id": invitePayload.callId ?? "",
                "sip_call_id": linphoneCallId ?? "",
                "call_uuid": invitePayload.uuid.uuidString,
                "remote_identity": invitePayload.handle,
            ])
            if snapshot.callUUID == nil {
                reportIncomingCall(payload: invitePayload)
            } else {
                if let uuid = resolvedCallUUID(from: nil) {
                    callKitManager?.refreshIncomingCallDisplay(callUUID: uuid, payload: invitePayload)
                }
                snapshot.callState = "incoming"
                snapshot.message = message ?? "Incoming call received"
                persistSnapshot()
                emitCallEvent(
                    state: "incoming",
                    remoteIdentity: snapshot.remoteIdentity,
                    callUUID: snapshot.callUUID,
                    callId: snapshot.callId,
                    message: snapshot.message,
                    extra: pendingIncomingPayload?.toFlutterDictionary() ?? [:]
                )
            }
            applyDeferredCallActionIfPossible()
        case LinphoneCallStateOutgoingInit:
            locallyTerminatedCall = nil
            cancelIncomingInviteTimeout()
            snapshot.callState = "calling"
            snapshot.speakerOn = selectedAudioRouteId == "speaker"
            snapshot.message = message ?? "Outgoing call initialized"
            print("IOSNativeSipManager LinphoneCallStateOutgoingInit -> speakerOn=\(snapshot.speakerOn), remote=\(remoteIdentity ?? "nil")")
            persistSnapshot()
            emitCallEvent(state: "calling", remoteIdentity: remoteIdentity, callId: snapshot.callId, message: snapshot.message)
        case LinphoneCallStateOutgoingProgress, LinphoneCallStateOutgoingRinging:
            cancelIncomingInviteTimeout()
            snapshot.callState = "ringing"
            snapshot.speakerOn = selectedAudioRouteId == "speaker"
            snapshot.message = message ?? "Outgoing call ringing"
            print("IOSNativeSipManager LinphoneCallStateOutgoingRinging -> speakerOn=\(snapshot.speakerOn), remote=\(remoteIdentity ?? "nil")")
            persistSnapshot()
            emitCallEvent(state: "ringing", remoteIdentity: remoteIdentity, callId: snapshot.callId, message: snapshot.message)
        case LinphoneCallStateConnected, LinphoneCallStateStreamsRunning:
            cancelIncomingInviteTimeout()
            let isFirstConnectedState = previousCallState != "in_call"
            if isFirstConnectedState, let uuid = resolvedCallUUID(from: nil) {
                callKitManager?.reportCallConnected(callUUID: uuid)
            }
            deferredAction = nil
            pendingIncomingPayload = nil
            snapshot.callState = "in_call"
            snapshot.message = message ?? "Call connected"
            configureAudioSessionForCallIfNeeded()
            selectPreferredNonSpeakerAudioDevice(reason: "call_connected")
            syncAudioRouteState(reason: "call_connected")
            if isFirstConnectedState {
                appendDiagnosticLog("media_connected", [
                    "call_id": snapshot.callId ?? "",
                    "sip_call_id": snapshot.sipCallId ?? "",
                    "remote_identity": remoteIdentity ?? "",
                ])
                appendDiagnosticLog("[VOIP] MEDIA_CONNECTED", [
                    "call_id": snapshot.callId ?? "",
                    "sip_call_id": snapshot.sipCallId ?? "",
                    "call_uuid": snapshot.callUUID ?? "",
                    "remote_identity": remoteIdentity ?? "",
                ])
            }
            endBackgroundTransitionTask(reason: "call-connected")
            persistSnapshot()
            if isFirstConnectedState {
                emitCallEvent(state: "in_call", remoteIdentity: remoteIdentity, callId: snapshot.callId, message: snapshot.message)
            }
        case LinphoneCallStateError:
            cancelIncomingInviteTimeout()
            let wasLocallyTerminated = call != nil && locallyTerminatedCall == call
            appendDiagnosticLog("[VOIP] CALL_TERMINATED", [
                "native_state": "error",
                "previous_state": previousCallState,
                "message": message ?? "",
                "call_id": snapshot.callId ?? "",
                "sip_call_id": snapshot.sipCallId ?? "",
                "call_uuid": snapshot.callUUID ?? "",
                "termination_origin": wasLocallyTerminated ? "local" : "remote",
            ])
            currentCall = nil
            if wasLocallyTerminated {
                locallyTerminatedCall = nil
                deferredAction = nil
                pendingIncomingPayload = nil
                return
            }
            let uuid = resolvedCallUUID(from: nil)
            let earlyTermination = isEarlyCallState(previousCallState)
            let remotelyDeclined = isRemoteDeclineMessage(message) || earlyTermination
            if let uuid {
                let endedReason: CXCallEndedReason =
                    previousCallState == "incoming" ? .unanswered :
                    (remotelyDeclined ? .remoteEnded : .failed)
                callKitManager?.reportCallEnded(callUUID: uuid, reason: endedReason)
            }
            snapshot.callState = remotelyDeclined ? "ended" : "failed"
            snapshot.message = message ?? (remotelyDeclined ? "Call declined by remote party" : "Call failed")
            deferredAction = nil
            pendingIncomingPayload = nil
            persistSnapshot()
            emitCallEvent(
                state: remotelyDeclined ? "ended" : "failed",
                remoteIdentity: remoteIdentity,
                callUUID: uuid?.uuidString,
                callId: snapshot.callId,
                message: snapshot.message
            )
            if let uuid {
                handleCallEnded(
                    reason: previousCallState == "incoming" ? .unanswered :
                        (remotelyDeclined ? .remoteEnded : .failed),
                    callUUID: uuid,
                    remoteIdentity: remoteIdentity
                )
            }
        case LinphoneCallStateEnd, LinphoneCallStateReleased:
            cancelIncomingInviteTimeout()
            let wasLocallyTerminated = call != nil && locallyTerminatedCall == call
            appendDiagnosticLog("[VOIP] CALL_TERMINATED", [
                "native_state": state == LinphoneCallStateEnd ? "end" : "released",
                "previous_state": previousCallState,
                "message": message ?? "",
                "call_id": snapshot.callId ?? "",
                "sip_call_id": snapshot.sipCallId ?? "",
                "call_uuid": snapshot.callUUID ?? "",
                "termination_origin": wasLocallyTerminated ? "local" : "remote",
            ])
            currentCall = nil
            if wasLocallyTerminated {
                if state == LinphoneCallStateReleased {
                    locallyTerminatedCall = nil
                }
                deferredAction = nil
                pendingIncomingPayload = nil
                return
            }
            let uuid = resolvedCallUUID(from: nil)
            if let uuid {
                callKitManager?.reportCallEnded(callUUID: uuid, reason: .remoteEnded)
                handleCallEnded(reason: .remoteEnded, callUUID: uuid, remoteIdentity: remoteIdentity)
            } else {
                snapshot.callState = "ended"
                snapshot.message = message ?? "Call ended"
                snapshot.remoteIdentity = nil
                snapshot.callId = nil
                persistSnapshot()
                emitCallEvent(state: "ended", message: snapshot.message)
            }
            deferredAction = nil
            pendingIncomingPayload = nil
            incomingPushReceivedAt = nil
            sipReadyQueuedAt = nil
        default:
            break
        }
    }

    private func beginBackgroundTransitionTask(reason: String) {
        guard backgroundTaskIdentifier == .invalid else { return }

        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "IOSNativeSipManager") { [weak self] in
            self?.appendDiagnosticLog("background_task_expired", [
                "reason": reason,
            ])
            self?.endBackgroundTransitionTask(reason: "expired")
        }

        appendDiagnosticLog("background_task_started", [
            "reason": reason,
        ])
    }

    private func endBackgroundTransitionTask(reason: String) {
        guard backgroundTaskIdentifier != .invalid else { return }

        let taskIdentifier = backgroundTaskIdentifier
        backgroundTaskIdentifier = .invalid
        UIApplication.shared.endBackgroundTask(taskIdentifier)
        appendDiagnosticLog("background_task_ended", [
            "reason": reason,
        ])
    }

    private func applyDeferredCallActionIfPossible() {
        guard let action = deferredAction else { return }

        // Clear before invoking Linphone. accept/decline/terminate can emit a
        // synchronous state callback which re-enters this method.
        deferredAction = nil
        let applied: Bool
        switch action {
        case .answer:
            applied = acceptCall(reason: "deferred-invite")
        case .decline:
            applied = declineCall()
        case .end:
            applied = hangup(reason: "deferred")
        }

        if !applied && deferredAction == nil {
            deferredAction = action
        }
    }

    private func isExpiredIncomingPush(_ payload: VoIPIncomingPayload) -> Bool {
        guard let issuedAt = payload.issuedAt else {
            // Compatibility while the backend timestamp rollout is in progress.
            return false
        }
        return Date().timeIntervalSince(issuedAt) > Constants.maximumIncomingPushAge
    }

    private func handleIncomingCallTerminationPush(_ payload: VoIPIncomingPayload) {
        let cancelledCallId = payload.callId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentCallId = snapshot.callId?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let cancelledCallId, !cancelledCallId.isEmpty, cancelledCallId == currentCallId else {
            appendDiagnosticLog("push_call_end_ignored", [
                "call_id": payload.callId ?? "",
                "current_call_id": snapshot.callId ?? "",
                "reason": "no_matching_active_call",
            ])
            return
        }

        let callUUID = snapshot.callUUID.flatMap(UUID.init(uuidString:)) ?? payload.uuid
        appendDiagnosticLog("push_call_ended", [
            "call_uuid": callUUID.uuidString,
            "call_id": cancelledCallId,
        ])
        callKitManager?.reportCallEnded(callUUID: callUUID, reason: .remoteEnded)
        handleCallEnded(reason: .remoteEnded, callUUID: callUUID, remoteIdentity: snapshot.remoteIdentity)
    }

    private func reportIncomingCall(payload: VoIPIncomingPayload, completion: (() -> Void)? = nil) {
        let isActuallyForeground = UIApplication.shared.applicationState == .active
        // A registered foreground core can receive the SIP INVITE before the
        // matching VoIP Push. Preserve that live call instead of resetting the
        // snapshot to idle and making Flutter wait for an INVITE it already has.
        let existingIncomingCall = isActuallyForeground ? resolveIncomingCallForAction() : nil
        snapshot.appForeground = isActuallyForeground

        if isActuallyForeground {
            if let core {
                linphone_core_enter_foreground(core)
                appendDiagnosticLog("linphone_enter_foreground", [
                    "reason": "voip-push-while-foreground",
                ])
            }
        } else {
            beginBackgroundTransitionTask(reason: "voip-push")
            if let core {
                linphone_core_enter_background(core)
                appendDiagnosticLog("linphone_enter_background", [
                    "reason": "voip-push",
                ])
            }
        }

        if isDuplicateIncomingPayload(payload) {
            let canonicalUUID = snapshot.callUUID.flatMap(UUID.init(uuidString:)) ?? payload.uuid
            let canonicalPayload = VoIPIncomingPayload(
                issuedAt: payload.issuedAt,
                eventType: payload.eventType,
                uuid: canonicalUUID,
                callId: payload.callId ?? snapshot.callId,
                handle: payload.handle,
                callerName: payload.callerName,
                hasVideo: payload.hasVideo,
                fromUri: payload.fromUri,
                toUri: payload.toUri,
                sipUri: payload.sipUri,
                bridgeUri: payload.bridgeUri
            )
            pendingIncomingPayload = canonicalPayload
            snapshot.callUUID = canonicalUUID.uuidString
            snapshot.callId = payload.callId ?? snapshot.callId
            snapshot.remoteIdentity = payload.handle
            snapshot.callState = snapshot.callState == "idle" ? "incoming" : snapshot.callState
            snapshot.message = "Incoming VoIP push deduplicated"
            persistSnapshot()
            emitCallEvent(
                state: snapshot.callState,
                remoteIdentity: payload.handle,
                callUUID: canonicalUUID.uuidString,
                callId: payload.callId ?? snapshot.callId,
                message: snapshot.message,
                extra: canonicalPayload.toFlutterDictionary()
            )
            appendDiagnosticLog("push_received_duplicate", [
                "call_uuid": canonicalUUID.uuidString,
                "duplicate_call_uuid": payload.uuid.uuidString,
                "call_id": payload.callId ?? "",
            ])
            scheduleIncomingInviteTimeout(for: canonicalPayload)
            completion?()
            return
        }

        pendingIncomingPayload = payload
        incomingPushReceivedAt = Date()
        sipReadyQueuedAt = nil
        callKitReportedForCurrentIncoming = false
        snapshot.callUUID = payload.uuid.uuidString
        snapshot.callId = payload.callId
        snapshot.sipCallId = existingIncomingCall.flatMap(callId(from:))
        snapshot.remoteIdentity = existingIncomingCall.flatMap(remoteIdentityString(from:)) ?? payload.handle
        if existingIncomingCall != nil {
            snapshot.callState = "incoming"
            snapshot.message = "Incoming SIP INVITE matched with foreground VoIP push"
        } else if isActuallyForeground {
            snapshot.callState = "idle"
            snapshot.message = "Incoming VoIP push received, waiting for SIP INVITE"
        } else {
            snapshot.callState = "incoming"
            snapshot.message = "Incoming VoIP push received"
        }
        appendDiagnosticLog("push_received", [
            "call_uuid": payload.uuid.uuidString,
            "call_id": payload.callId ?? "",
            "remote_identity": payload.handle,
            "caller_name": payload.callerName ?? "",
            "foreground": isActuallyForeground ? "true" : "false",
        ])
        appendDiagnosticLog("[VOIP] PUSH_RECEIVED", [
            "call_id": payload.callId ?? "",
            "call_uuid": payload.uuid.uuidString,
            "extension": loadPersistedRegistrationConfig()?.login ?? "",
            "caller": payload.handle,
            "foreground": isActuallyForeground ? "true" : "false",
        ])
        appendDiagnosticLog("[VOIP] CORE_STARTED", [
            "call_id": payload.callId ?? "",
            "call_uuid": payload.uuid.uuidString,
            "extension": loadPersistedRegistrationConfig()?.login ?? "",
        ])
        persistSnapshot()
        if let existingIncomingCall {
            let sipCallId = callId(from: existingIncomingCall)
            appendDiagnosticLog("foreground_push_attached_existing_invite", [
                "call_uuid": payload.uuid.uuidString,
                "call_id": payload.callId ?? "",
                "sip_call_id": sipCallId ?? "",
            ])
            emitCallEvent(
                state: "incoming",
                remoteIdentity: snapshot.remoteIdentity,
                callUUID: payload.uuid.uuidString,
                callId: payload.callId,
                message: snapshot.message,
                extra: payload.toFlutterDictionary().merging([
                    "sipCallId": sipCallId ?? NSNull(),
                ]) { _, new in new }
            )
        } else if isActuallyForeground {
            appendDiagnosticLog("foreground_push_waiting_for_invite", [
                "call_uuid": payload.uuid.uuidString,
                "call_id": payload.callId ?? "",
            ])
        } else {
            emitCallEvent(
                state: "incoming",
                remoteIdentity: payload.handle,
                callUUID: payload.uuid.uuidString,
                callId: payload.callId,
                message: "Incoming VoIP push received",
                extra: payload.toFlutterDictionary()
            )
        }
        if existingIncomingCall == nil {
            scheduleIncomingInviteTimeout(for: payload)
        }

        reportIncomingCallToSystemIfNeeded(payload: payload, completion: completion)
    }

    private func emitSipReadyIfNeeded(reason: String) {
        guard let payload = pendingIncomingPayload else { return }
        guard snapshot.registrationState == "registered" else { return }

        let config = loadPersistedRegistrationConfig()
        let sipExtension = config?.login.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let callUUID = snapshot.callUUID ?? payload.uuid.uuidString
        // Test flow: callId must stay the Push/Linkedid id; SIP Call-ID is emitted separately.
        // Previous behavior could send the Linphone SIP Call-ID here after INVITE overwrote snapshot.callId.
        let callId = snapshot.callId ?? payload.callId ?? ""
        let sipCallId = snapshot.sipCallId ?? ""
        let dedupeKey = "\(callId)|\(callUUID)|\(sipExtension)"

        guard !callId.isEmpty || !callUUID.isEmpty else { return }
        guard lastEmittedSipReadyKey != dedupeKey else {
            appendDiagnosticLog("sip_ready_skipped_duplicate", [
                "reason": reason,
                "call_uuid": callUUID,
                "call_id": callId,
                "extension": sipExtension,
            ])
            return
        }

        lastEmittedSipReadyKey = dedupeKey
        sipReadyQueuedAt = Date()
        appendDiagnosticLog("sip_ready_event_queued", [
            "reason": reason,
            "call_uuid": callUUID,
            "call_id": callId,
            "sip_call_id": sipCallId,
            "extension": sipExtension,
        ])
        appendDiagnosticLog("[VOIP] SIP_READY_QUEUED", [
            "reason": reason,
            "call_uuid": callUUID,
            "call_id": callId,
            "sip_call_id": sipCallId,
            "extension": sipExtension,
        ])
        emit([
            "type": "sip_ready",
            "reason": reason,
            "callUUID": callUUID,
            "callId": callId,
            "sipCallId": sipCallId.isEmpty ? NSNull() : sipCallId,
            "extension": sipExtension,
            "remoteIdentity": payload.handle,
        ])
    }

    private func reportIncomingCallToSystemIfNeeded(
        payload: VoIPIncomingPayload,
        completion: (() -> Void)? = nil
    ) {
        if callKitReportedForCurrentIncoming {
            completion?()
            return
        }

        let applicationState = UIApplication.shared.applicationState
        let isActuallyForeground = applicationState == .active
        snapshot.appForeground = isActuallyForeground

        guard !isActuallyForeground else {
            appendDiagnosticLog("callkit_skipped_foreground", [
                "call_uuid": payload.uuid.uuidString,
                "call_id": payload.callId ?? "",
                "application_state": String(describing: applicationState),
            ])
            persistSnapshot()
            completion?()
            return
        }

        guard let callKitManager else {
            appendDiagnosticLog("callkit_report_skipped", [
                "call_uuid": payload.uuid.uuidString,
                "reason": "callkit_unavailable",
            ])
            completion?()
            return
        }

        callKitManager.reportIncomingCall(payload: payload) { [weak self] error in
            defer { completion?() }
            guard let self else { return }

            if let error {
                self.appendDiagnosticLog("callkit_report_failed", [
                    "call_uuid": payload.uuid.uuidString,
                    "message": error.localizedDescription,
                ])
                self.snapshot.callState = "failed"
                self.snapshot.message = error.localizedDescription
                self.persistSnapshot()
                self.emitCallEvent(
                    state: "failed",
                    remoteIdentity: payload.handle,
                    callUUID: payload.uuid.uuidString,
                    callId: payload.callId,
                    message: error.localizedDescription
                )
            } else {
                self.callKitReportedForCurrentIncoming = true
                self.appendDiagnosticLog("callkit_reported", [
                    "call_uuid": payload.uuid.uuidString,
                    "call_id": payload.callId ?? "",
                ])
            }
        }
    }

    private func scheduleIncomingInviteTimeout(for payload: VoIPIncomingPayload) {
        incomingInviteTimeoutTimer?.invalidate()
        incomingInviteTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            guard let self else { return }
            guard self.snapshot.callUUID == payload.uuid.uuidString else { return }
            guard self.currentCall == nil else { return }
            guard self.snapshot.callState == "incoming" ||
                    self.snapshot.callState == "idle" ||
                    self.snapshot.callState == "ringing" else { return }

            self.appendDiagnosticLog("incoming_invite_timeout", [
                "call_uuid": payload.uuid.uuidString,
                "call_id": payload.callId ?? "",
                "foreground": self.snapshot.appForeground ? "true" : "false",
                "call_state": self.snapshot.callState,
            ])

            if self.callKitReportedForCurrentIncoming {
                self.callKitManager?.reportCallEnded(callUUID: payload.uuid, reason: .unanswered)
            }

            self.pendingIncomingPayload = nil
            self.deferredAction = nil
            self.handleCallEnded(
                reason: .unanswered,
                callUUID: payload.uuid,
                remoteIdentity: payload.handle
            )
        }
    }

    private func cancelIncomingInviteTimeout() {
        incomingInviteTimeoutTimer?.invalidate()
        incomingInviteTimeoutTimer = nil
    }

    private func isDuplicateIncomingPayload(_ payload: VoIPIncomingPayload) -> Bool {
        let currentState = snapshot.callState
        guard currentState == "incoming" ||
                currentState == "ringing" ||
                currentState == "in_call" else {
            return false
        }

        if snapshot.callUUID == payload.uuid.uuidString {
            return true
        }

        if let payloadCallId = payload.callId,
           let snapshotCallId = snapshot.callId,
           payloadCallId == snapshotCallId {
            return true
        }

        let payloadIdentities = normalizedIncomingIdentities(for: payload)
        if let snapshotRemote = normalizedIdentityForMatching(snapshot.remoteIdentity),
           payloadIdentities.contains(snapshotRemote) {
            return true
        }

        if let pendingPayload = pendingIncomingPayload {
            let pendingIdentities = normalizedIncomingIdentities(for: pendingPayload)
            if !payloadIdentities.isDisjoint(with: pendingIdentities) {
                return true
            }
        }

        return false
    }

    private func normalizedIncomingIdentities(for payload: VoIPIncomingPayload) -> Set<String> {
        let candidates = [
            payload.handle,
            payload.callerName,
            payload.fromUri,
            payload.sipUri,
            payload.bridgeUri,
        ]

        return Set(candidates.compactMap { normalizedIdentityForMatching($0) })
    }

    private func emitPushTokenEvent(token: String) {
        emit([
            "type": "push_token",
            "platform": "ios",
            "provider": "apns_voip",
            "pushType": "voip",
            "token": token,
        ])
    }

    private func emitRegistrationEvent(state: String, message: String?) {
        emit([
            "type": "registration",
            "state": state,
            "message": message ?? NSNull(),
        ])
    }

    private func emitCallEvent(
        state: String,
        remoteIdentity: String? = nil,
        callUUID: String? = nil,
        callId: String? = nil,
        message: String? = nil,
        extra: [String: Any] = [:]
    ) {
        updateProximityMonitoring(callState: state, reason: "call_event")
        print("IOSNativeSipManager emitCallEvent -> state=\(state), speakerOn=\(snapshot.speakerOn), remote=\(remoteIdentity ?? snapshot.remoteIdentity ?? "nil"), message=\(message ?? snapshot.message ?? "nil")")
        var event: [String: Any] = [
            "type": "call",
            "state": state,
            "remoteIdentity": (remoteIdentity ?? snapshot.remoteIdentity) as Any? ?? NSNull(),
            "callUUID": (callUUID ?? snapshot.callUUID) as Any? ?? NSNull(),
            "callId": (callId ?? snapshot.callId) as Any? ?? NSNull(),
            "message": (message ?? snapshot.message) as Any? ?? NSNull(),
            "muted": snapshot.muted,
            "speakerOn": snapshot.speakerOn,
        ]
        extra.forEach { event[$0.key] = $0.value }
        emit(event)
    }

    private func emitCallActionEvent(
        action: String,
        callUUID: UUID,
        payload: VoIPIncomingPayload?
    ) {
        appendDiagnosticLog(action == "answer" ? "callkit_answer" : "callkit_\(action)", [
            "call_uuid": callUUID.uuidString,
            "call_id": payload?.callId ?? snapshot.callId ?? "",
        ])
        let queuedAction = QueuedCallAction(
            action: action,
            callUUID: callUUID.uuidString,
            handle: payload?.handle ?? snapshot.remoteIdentity,
            callerName: payload?.callerName,
            callId: payload?.callId ?? snapshot.callId,
            fromUri: payload?.fromUri,
            toUri: payload?.toUri,
            sipUri: payload?.sipUri,
            timestamp: Date().timeIntervalSince1970
        )

        var pending = loadPendingCallActions()
        pending.append(queuedAction)
        savePendingCallActions(pending)

        emit([
            "type": "call_action",
            "action": action,
            "callUUID": callUUID.uuidString,
            "callId": queuedAction.callId ?? NSNull(),
            "remoteIdentity": queuedAction.handle ?? NSNull(),
            "callerName": queuedAction.callerName ?? NSNull(),
            "fromUri": queuedAction.fromUri ?? NSNull(),
            "toUri": queuedAction.toUri ?? NSNull(),
            "sipUri": queuedAction.sipUri ?? NSNull(),
            "timestamp": queuedAction.timestamp,
        ])
    }

    private func handleCallEnded(reason: CXCallEndedReason, callUUID: UUID, remoteIdentity: String?) {
        cancelIncomingInviteTimeout()
        callKitReportedForCurrentIncoming = false
        let endedCallId = snapshot.callId
        appendDiagnosticLog("call_end_reason", [
            "reason": endedReasonString(for: reason),
            "call_uuid": callUUID.uuidString,
            "call_id": endedCallId ?? "",
            "remote_identity": remoteIdentity ?? "",
        ])
        snapshot.callUUID = nil
        snapshot.callId = nil
        snapshot.callState = "ended"
        snapshot.remoteIdentity = nil
        snapshot.message = endedMessage(for: reason)
        snapshot.muted = false
        snapshot.speakerOn = false
        selectedAudioRouteId = nil
        persistSnapshot()
        emitCallEvent(
            state: "ended",
            remoteIdentity: remoteIdentity,
            callUUID: callUUID.uuidString,
            callId: endedCallId,
            message: snapshot.message
        )
        emit([
            "type": "call_end_reason",
            "reason": endedReasonString(for: reason),
            "callUUID": callUUID.uuidString,
            "callId": endedCallId ?? NSNull(),
            "remoteIdentity": remoteIdentity ?? NSNull(),
        ])
    }

    private func emit(_ event: [String: Any]) {
        DispatchQueue.main.async {
            if let eventSink = self.eventSink {
                eventSink(event)
            } else {
                self.pendingEvents.append(event)
            }
        }
    }

    private func persistSnapshot() {
        if let encoded = try? JSONEncoder().encode(snapshot) {
            defaults.set(encoded, forKey: Constants.snapshotKey)
        }
    }

    private func appendDiagnosticLog(_ event: String, _ details: [String: String]) {
        var logs = loadDiagnosticLogs()
        logs.append(
            NativeDiagnosticEntry(
                timestamp: Date().timeIntervalSince1970,
                event: event,
                details: details
            )
        )
        if logs.count > Constants.diagnosticLogsLimit {
            logs.removeFirst(logs.count - Constants.diagnosticLogsLimit)
        }
        saveDiagnosticLogs(logs)
    }

    private func saveDiagnosticLogs(_ logs: [NativeDiagnosticEntry]) {
        if let encoded = try? JSONEncoder().encode(logs) {
            defaults.set(encoded, forKey: Constants.diagnosticLogsKey)
        }
    }

    private func loadDiagnosticLogs() -> [NativeDiagnosticEntry] {
        guard
            let data = defaults.data(forKey: Constants.diagnosticLogsKey),
            let decoded = try? JSONDecoder().decode([NativeDiagnosticEntry].self, from: data)
        else {
            return []
        }
        return decoded
    }

    private func clearDiagnosticLogs() {
        defaults.removeObject(forKey: Constants.diagnosticLogsKey)
    }

    private static func loadSnapshot(from defaults: UserDefaults) -> NativeSipSnapshot {
        guard
            let data = defaults.data(forKey: Constants.snapshotKey),
            let decoded = try? JSONDecoder().decode(NativeSipSnapshot.self, from: data)
        else {
            return NativeSipSnapshot.initial()
        }
        return decoded
    }

    private func persistRegistrationConfig(_ config: NativeSipRegistrationConfig) {
        if let encoded = try? JSONEncoder().encode(config) {
            defaults.set(encoded, forKey: Constants.registrationConfigKey)
        }
    }

    private func loadPersistedRegistrationConfig() -> NativeSipRegistrationConfig? {
        guard
            let data = defaults.data(forKey: Constants.registrationConfigKey),
            let decoded = try? JSONDecoder().decode(NativeSipRegistrationConfig.self, from: data)
        else {
            return nil
        }
        return decoded
    }

    private func clearPersistedRegistrationConfig() {
        defaults.removeObject(forKey: Constants.registrationConfigKey)
    }

    private func savePendingCallActions(_ actions: [QueuedCallAction]) {
        let sanitized = sanitizePendingCallActions(actions)
        if let encoded = try? JSONEncoder().encode(sanitized) {
            defaults.set(encoded, forKey: Constants.pendingCallActionsKey)
        } else {
            defaults.removeObject(forKey: Constants.pendingCallActionsKey)
        }
    }

    private func loadPendingCallActions() -> [QueuedCallAction] {
        guard
            let data = defaults.data(forKey: Constants.pendingCallActionsKey),
            let decoded = try? JSONDecoder().decode([QueuedCallAction].self, from: data)
        else {
            return []
        }
        return decoded
    }

    private func sanitizePendingCallActions(_ actions: [QueuedCallAction]) -> [QueuedCallAction] {
        let freshActions = actions.filter { Date().timeIntervalSince1970 - $0.timestamp <= 120 }
        var deduplicated: [QueuedCallAction] = []

        for action in freshActions.sorted(by: { $0.timestamp < $1.timestamp }) {
            if let existingIndex = deduplicated.firstIndex(where: {
                $0.action == action.action && $0.callUUID == action.callUUID
            }) {
                deduplicated[existingIndex] = action
            } else {
                deduplicated.append(action)
            }
        }

        return deduplicated
    }

    private func resolvedCallUUID(from arguments: [String: Any]?) -> UUID? {
        if let rawUUID = arguments?["callUUID"] as? String, let uuid = UUID(uuidString: rawUUID) {
            return uuid
        }
        if let snapshotUUID = snapshot.callUUID {
            return UUID(uuidString: snapshotUUID)
        }
        return nil
    }

    private func callEndedReason(from value: String?) -> CXCallEndedReason {
        switch value?.lowercased() {
        case "failed":
            return .failed
        case "unanswered", "missed":
            return .unanswered
        case "answered_elsewhere":
            return .answeredElsewhere
        case "declined_elsewhere":
            return .declinedElsewhere
        default:
            return .remoteEnded
        }
    }

    private func endedReasonString(for reason: CXCallEndedReason) -> String {
        switch reason {
        case .failed:
            return "failed"
        case .remoteEnded:
            return "remote_ended"
        case .unanswered:
            return "unanswered"
        case .answeredElsewhere:
            return "answered_elsewhere"
        case .declinedElsewhere:
            return "declined_elsewhere"
        @unknown default:
            return "unknown"
        }
    }

    private func endedMessage(for reason: CXCallEndedReason) -> String {
        switch reason {
        case .failed:
            return "System call failed"
        case .remoteEnded:
            return "Call ended remotely"
        case .unanswered:
            return "Call was not answered"
        case .answeredElsewhere:
            return "Call answered elsewhere"
        case .declinedElsewhere:
            return "Call declined elsewhere"
        @unknown default:
            return "Call ended"
        }
    }

    private func buildIdentityUri(login: String, server: String) -> String {
        if login.hasPrefix("sip:") {
            return login
        }
        if login.contains("@") {
            return "sip:\(login)"
        }
        return "sip:\(login)@\(server)"
    }

    private func buildServerUri(server: String, port: Int, transport: String) -> String {
        "sip:\(server):\(port);transport=\(transport)"
    }

    private func transportType(for value: String) -> LinphoneTransportType {
        value == "tcp" ? LinphoneTransportTcp : LinphoneTransportUdp
    }

    private func remoteIdentityString(from call: OpaquePointer) -> String? {
        guard let address = linphone_call_get_remote_address(call) else {
            return nil
        }
        guard let raw = linphone_address_as_string_uri_only(address) else {
            return nil
        }
        defer { bctbx_free(raw) }
        return String(cString: raw)
    }

    private func callId(from call: OpaquePointer) -> String? {
        guard
            let callLog = linphone_call_get_call_log(call),
            let rawCallId = linphone_call_log_get_call_id(callLog)
        else {
            return nil
        }
        return String(cString: rawCallId)
    }

    private func isRemoteDeclineMessage(_ message: String?) -> Bool {
        guard let normalized = message?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !normalized.isEmpty else {
            return false
        }

        return normalized.contains("486") ||
            normalized.contains("603") ||
            normalized.contains("decline") ||
            normalized.contains("declined") ||
            normalized.contains("busy here") ||
            normalized.contains("busy") ||
            normalized.contains("canceled") ||
            normalized.contains("cancelled") ||
            normalized.contains("request terminated")
    }

    private func isEarlyCallState(_ value: String) -> Bool {
        value == "incoming" || value == "calling" || value == "ringing"
    }

    private func linphonePaths() -> (base: URL, config: URL, cache: URL) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("linphone", isDirectory: true)
        return (
            base: base,
            config: base.appendingPathComponent("linphonerc"),
            cache: base.appendingPathComponent("cache", isDirectory: true)
        )
    }

    static func string(from pointer: UnsafePointer<CChar>?) -> String? {
        guard let pointer else { return nil }
        return String(cString: pointer)
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        events([
            "type": "native",
            "state": "stream_attached",
            "platform": "ios",
        ] as [String: Any])

        events([
            "type": "registration",
            "state": snapshot.registrationState,
            "message": snapshot.message ?? NSNull(),
        ] as [String: Any])

        events([
            "type": "call",
            "state": snapshot.callState,
            "remoteIdentity": snapshot.remoteIdentity ?? NSNull(),
            "callUUID": snapshot.callUUID ?? NSNull(),
            "callId": snapshot.callId ?? NSNull(),
            "message": snapshot.message ?? NSNull(),
            "muted": snapshot.muted,
            "speakerOn": snapshot.speakerOn,
        ] as [String: Any])

        events([
            "type": "pending_call_actions",
            "actions": loadPendingCallActions().map { $0.toFlutterDictionary() },
        ] as [String: Any])

        events([
            "type": "app_visibility",
            "appForeground": snapshot.appForeground,
            "callState": snapshot.callState,
            "remoteIdentity": snapshot.remoteIdentity as Any? ?? NSNull(),
        ] as [String: Any])

        events([
            "type": "audio_session",
            "state": "snapshot",
            "reason": "stream_attached",
            "output": currentAudioOutputKind(route: AVAudioSession.sharedInstance().currentRoute),
            "route": audioRouteDescription(AVAudioSession.sharedInstance().currentRoute),
            "speakerOn": snapshot.speakerOn,
            "callState": snapshot.callState,
        ] as [String: Any])

        if let token = defaults.string(forKey: Constants.voipTokenKey), !token.isEmpty {
            events([
                "type": "push_token",
                "platform": "ios",
                "provider": "apns_voip",
                "pushType": "voip",
                "token": token,
            ] as [String: Any])
        }

        self.eventSink = events
        let queued = pendingEvents
        pendingEvents.removeAll()
        queued.forEach { events($0) }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

extension IOSNativeSipManager: IOSVoIPPushManagerDelegate {
    func voipPushManager(_ manager: IOSVoIPPushManager, didUpdate token: String) {
        defaults.set(token, forKey: Constants.voipTokenKey)
        emitPushTokenEvent(token: token)
        _ = refreshAccountPushNotificationConfig(reason: "voip-token-updated")
    }

    func voipPushManagerDidInvalidateToken(_ manager: IOSVoIPPushManager) {
        defaults.removeObject(forKey: Constants.voipTokenKey)
        appendDiagnosticLog("voip_token_invalidated", [:])
        emit([
            "type": "push_token_invalidated",
            "platform": "ios",
            "provider": "apns_voip",
        ])
    }

    func voipPushManager(
        _ manager: IOSVoIPPushManager,
        didReceiveIncoming payload: VoIPIncomingPayload,
        completion: @escaping () -> Void
    ) {
        if payload.isTerminationEvent {
            handleIncomingCallTerminationPush(payload)
            completion()
            return
        }
        guard !isExpiredIncomingPush(payload) else {
            appendDiagnosticLog("push_received_expired", [
                "call_uuid": payload.uuid.uuidString,
                "call_id": payload.callId ?? "",
                "issued_at_ms": payload.issuedAt.map { String(Int64($0.timeIntervalSince1970 * 1000)) } ?? "",
                "max_age_seconds": String(Int(Constants.maximumIncomingPushAge)),
            ])
            completion()
            return
        }
        // Persist the Push/Linkedid identity before any REGISTER callback can fire.
        // This prevents a fast registration result from emitting sip-ready with
        // identifiers left over from the previous call.
        reportIncomingCall(payload: payload, completion: completion)

        if let account, linphone_account_get_state(account) == LinphoneRegistrationOk {
            appendDiagnosticLog("sip_register_refresh_skipped", [
                "reason": "voip-push-already-registered",
                "account_state": currentAccountRegistrationStateString(),
            ])
            emitSipReadyIfNeeded(reason: "voip-push-already-registered")
        } else {
            _ = refreshRegistrationIfPossible(reason: "voip-push", emitRegisteringEvent: true) ||
                restoreRegistrationIfNeeded(reason: "voip-push", emitRegisteringEvent: true)
        }
    }
}

extension IOSNativeSipManager: IOSCallKitManagerDelegate {
    func callKitManager(
        _ manager: IOSCallKitManager,
        didReceiveAnswerFor callUUID: UUID,
        payload: VoIPIncomingPayload?
    ) {
        if snapshot.callState == "in_call" {
            appendDiagnosticLog("callkit_answer_ignored_already_connected", [
                "call_uuid": callUUID.uuidString,
                "call_id": payload?.callId ?? snapshot.callId ?? "",
            ])
            callKitManager?.reportCallConnected(callUUID: callUUID)
            return
        }

        snapshot.callUUID = callUUID.uuidString
        snapshot.callId = payload?.callId ?? snapshot.callId
        snapshot.callState = "ringing"
        snapshot.remoteIdentity = payload?.handle ?? snapshot.remoteIdentity
        snapshot.message = "System answer action received"
        persistSnapshot()
        emitCallActionEvent(action: "answer", callUUID: callUUID, payload: payload)
        let accepted = acceptCall(reason: "callkit")
        // CallKit's answer transaction must be completed immediately even when
        // the real SIP INVITE is still in flight. Media connection is reported
        // separately once Linphone reaches Connected/StreamsRunning.
        callKitManager?.completeAnswerAction(callUUID: callUUID, accepted: accepted)
    }

    func callKitManager(
        _ manager: IOSCallKitManager,
        didReceiveEndFor callUUID: UUID,
        payload: VoIPIncomingPayload?
    ) {
        let action = snapshot.callState == "incoming" ? "decline" : "end"
        emitCallActionEvent(action: action, callUUID: callUUID, payload: payload)
        if action == "decline" {
            let didDeclineImmediately = declineCall()
            if !didDeclineImmediately {
                deferredAction = .decline
                handleCallEnded(
                    reason: .unanswered,
                    callUUID: callUUID,
                    remoteIdentity: payload?.handle ?? snapshot.remoteIdentity
                )
                return
            }
            handleCallEnded(
                reason: .unanswered,
                callUUID: callUUID,
                remoteIdentity: payload?.handle ?? snapshot.remoteIdentity
            )
        } else {
            let didHangupImmediately = hangup(reason: "callkit")
            if !didHangupImmediately {
                deferredAction = .end
                handleCallEnded(
                    reason: .remoteEnded,
                    callUUID: callUUID,
                    remoteIdentity: payload?.handle ?? snapshot.remoteIdentity
                )
                return
            }
        }
    }

    func callKitManagerDidActivateAudioSession(_ manager: IOSCallKitManager) {
        configureAudioSessionForCallIfNeeded()
        // На ранней стадии исходящего звонка iOS/CallKit иногда временно
        // сообщает speaker-route, хотя пользователь не включал громкую связь.
        // Не продвигаем это состояние в UI автоматически.
        emitAudioSessionEvent(state: "activated")
    }

    func callKitManagerDidDeactivateAudioSession(_ manager: IOSCallKitManager) {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            emitAudioSessionEvent(state: "deactivation_failed", reason: error.localizedDescription)
        }
        emitAudioSessionEvent(state: "deactivated")
    }

    func callKitManagerDidReset(_ manager: IOSCallKitManager) {
        cancelIncomingInviteTimeout()
        callKitReportedForCurrentIncoming = false
        currentCall = nil
        pendingIncomingPayload = nil
        deferredAction = nil
        savePendingCallActions([])
        appendDiagnosticLog("callkit_reset", [:])
        snapshot = NativeSipSnapshot.initial()
        persistSnapshot()
        emitCallEvent(state: "ended", message: "CallKit provider reset")
    }
}

import AVFAudio
import CallKit
import Flutter
import PushKit
import UIKit
import linphone

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
            callId: nil
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
            "systemAlertWindowGranted": true,
            "appForeground": appForeground,
            "callUUID": callUUID ?? NSNull(),
            "callId": callId ?? NSNull(),
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

struct VoIPIncomingPayload {
    let uuid: UUID
    let callId: String?
    let handle: String
    let callerName: String?
    let hasVideo: Bool
    let fromUri: String?
    let toUri: String?
    let sipUri: String?

    func toFlutterDictionary() -> [String: Any] {
        [
            "callUUID": uuid.uuidString,
            "callId": callId ?? NSNull(),
            "remoteIdentity": handle,
            "callerName": callerName ?? NSNull(),
            "hasVideo": hasVideo,
            "fromUri": fromUri ?? NSNull(),
            "toUri": toUri ?? NSNull(),
            "sipUri": sipUri ?? NSNull(),
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

        let callId = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: ["call_id", "callId", "sip_call_id", "sipCallId", "id"]
        )
        let uuid = UUID(uuidString: rawUUID ?? "") ?? UUID(uuidString: callId ?? "") ?? UUID()

        let callerName = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary, alertDictionary],
            keys: ["caller_name", "callerName", "display_name", "displayName", "from_name", "name", "title"]
        )

        let handle = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: [
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
            keys: ["from_uri", "fromUri", "from"]
        )

        let toUri = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: ["to_uri", "toUri", "to"]
        )

        let sipUri = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: ["sip_uri", "sipUri", "invite_uri", "inviteUri", "uri"]
        )

        let hasVideo = firstBool(
            in: userInfo,
            nested: [dataDictionary, callDictionary, sipDictionary],
            keys: ["has_video", "hasVideo", "video", "is_video"]
        ) ?? false

        return VoIPIncomingPayload(
            uuid: uuid,
            callId: callId,
            handle: handle,
            callerName: callerName,
            hasVideo: hasVideo,
            fromUri: fromUri,
            toUri: toUri,
            sipUri: sipUri
        )
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

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: handleType(for: payload.handle), value: payload.handle)
        update.localizedCallerName = payload.callerName
        update.hasVideo = payload.hasVideo
        update.supportsDTMF = true
        update.supportsGrouping = false
        update.supportsHolding = false
        update.supportsUngrouping = false

        provider.reportNewIncomingCall(with: payload.uuid, update: update) { [weak self] error in
            if error != nil {
                self?.payloadsByUUID.removeValue(forKey: payload.uuid)
            }
            completion(error)
        }
    }

    func payload(for callUUID: UUID) -> VoIPIncomingPayload? {
        payloadsByUUID[callUUID]
    }

    func reportCallConnected(callUUID: UUID) {
        if let action = pendingAnswerActions.removeValue(forKey: callUUID) {
            action.fulfill()
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
    }

    private let defaults = UserDefaults.standard
    private let methodChannel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel
    private let voipPushManager = IOSVoIPPushManager()
    private let callKitManager = IOSCallKitManager()

    private var eventSink: FlutterEventSink?
    private var pendingEvents: [[String: Any]] = []
    private var snapshot: NativeSipSnapshot
    private var initialized = false

    private var core: OpaquePointer?
    private var coreCallbacks: OpaquePointer?
    private var account: OpaquePointer?
    private var currentCall: OpaquePointer?
    private var pendingIncomingPayload: VoIPIncomingPayload?
    private var deferredAction: DeferredNativeCallAction?

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
        voipPushManager.delegate = self
        callKitManager.delegate = self
    }

    deinit {
        teardownLinphoneCore()
    }

    func initializeRuntimeIfNeeded() {
        guard !initialized else { return }
        initialized = true
        updateAppVisibility(isForeground: UIApplication.shared.applicationState == .active)
        voipPushManager.start()
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
        persistSnapshot()
        emit([
            "type": "app_visibility",
            "appForeground": isForeground,
            "callState": snapshot.callState,
            "remoteIdentity": snapshot.remoteIdentity ?? NSNull(),
        ])
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
        case "consumePendingCallActions":
            let actions = loadPendingCallActions()
            savePendingCallActions([])
            result(actions.map { $0.toFlutterDictionary() })
        case "simulateIncomingCall":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Arguments are required", details: nil))
                return
            }
            let payload = VoIPIncomingPayload(
                uuid: UUID(uuidString: args["callUUID"] as? String ?? "") ?? UUID(),
                callId: args["callId"] as? String,
                handle: ((args["handle"] as? String) ?? "Unknown").trimmingCharacters(in: .whitespacesAndNewlines),
                callerName: args["callerName"] as? String,
                hasVideo: args["hasVideo"] as? Bool ?? false,
                fromUri: args["fromUri"] as? String,
                toUri: args["toUri"] as? String,
                sipUri: args["sipUri"] as? String
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
            result(restoreRegistrationIfNeeded())
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
            result(acceptCall())
        case "declineCall":
            result(declineCall())
        case "hangup":
            result(hangup())
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
        case "reportCallConnected":
            guard let uuid = resolvedCallUUID(from: call.arguments as? [String: Any]) else {
                result(false)
                return
            }
            callKitManager.reportCallConnected(callUUID: uuid)
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
            callKitManager.reportCallEnded(callUUID: uuid, reason: reason)
            handleCallEnded(reason: reason, callUUID: uuid, remoteIdentity: snapshot.remoteIdentity)
            result(true)
        case "endSystemCall":
            guard let uuid = resolvedCallUUID(from: call.arguments as? [String: Any]) else {
                result(false)
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

        if config.transport == "tcp" {
            linphone_account_params_enable_outbound_proxy(params, 1)
        }

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

    private func restoreRegistrationIfNeeded() -> Bool {
        guard snapshot.persistentEnabled, let config = loadPersistedRegistrationConfig() else {
            return false
        }

        if let account, linphone_account_get_state(account) == LinphoneRegistrationOk {
            return true
        }

        return applyRegistrationConfig(config, emitRegisteringEvent: false)
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
        snapshot.remoteIdentity = target
        snapshot.message = "Outgoing call started"
        snapshot.callId = callId(from: call) ?? snapshot.callId
        persistSnapshot()
        emitCallEvent(state: "calling", remoteIdentity: target, callId: snapshot.callId, message: snapshot.message)
        return true
    }

    private func acceptCall() -> Bool {
        guard let call = resolveIncomingCallForAction() else {
            deferredAction = .answer
            return false
        }

        guard let params = core.flatMap({ linphone_core_create_call_params($0, call) }) else {
            return linphone_call_accept(call) == 0
        }

        linphone_call_params_enable_video(params, 0)
        let status = linphone_call_accept_with_params(call, params)
        linphone_call_params_unref(params)
        return status == 0
    }

    private func declineCall() -> Bool {
        if let call = resolveIncomingCallForAction() {
            return linphone_call_decline(call, LinphoneReasonDeclined) == 0
        }

        deferredAction = .decline
        return true
    }

    private func hangup() -> Bool {
        if let call = resolveCurrentCallForAction() {
            return linphone_call_terminate(call) == 0
        }

        deferredAction = .end
        return false
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
        guard let call = resolveCurrentCallForAction(), let core else {
            snapshot.speakerOn = enabled
            persistSnapshot()
            emitCallEvent(state: snapshot.callState, message: snapshot.message)
            return false
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
                if !enabled, type == LinphoneAudioDeviceTypeEarpiece {
                    selected = device
                    break
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
                return false
            }
        }

        snapshot.speakerOn = enabled
        persistSnapshot()
        emitCallEvent(state: snapshot.callState, message: snapshot.message)
        return true
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
        return nil
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
            emitRegistrationEvent(state: "registering", message: snapshot.message)
        case LinphoneRegistrationOk:
            snapshot.registrationState = "registered"
            snapshot.message = message ?? "Registration successful"
            snapshot.persistentEnabled = true
            emitRegistrationEvent(state: "registered", message: snapshot.message)
        case LinphoneRegistrationFailed:
            snapshot.registrationState = "failed"
            snapshot.message = message ?? "Registration failed"
            emitRegistrationEvent(state: "failed", message: snapshot.message)
        case LinphoneRegistrationCleared:
            snapshot.registrationState = "disconnected"
            snapshot.message = message ?? "Unregistration done"
            emitRegistrationEvent(state: "disconnected", message: snapshot.message)
        default:
            snapshot.registrationState = "disconnected"
            snapshot.message = message
            emitRegistrationEvent(state: "disconnected", message: snapshot.message)
        }

        persistSnapshot()
    }

    fileprivate func handleLinphoneCallStateChanged(
        call: OpaquePointer?,
        state: LinphoneCallState,
        message: String?
    ) {
        if let call {
            currentCall = call
        }

        let remoteIdentity = call.flatMap(remoteIdentityString(from:))
        let linphoneCallId = call.flatMap(callId(from:))
        if let linphoneCallId {
            snapshot.callId = linphoneCallId
        }
        if let remoteIdentity {
            snapshot.remoteIdentity = remoteIdentity
        }

        switch state {
        case LinphoneCallStateIncomingReceived, LinphoneCallStatePushIncomingReceived:
            if snapshot.callUUID == nil {
                let payload = VoIPIncomingPayload(
                    uuid: UUID(),
                    callId: linphoneCallId,
                    handle: remoteIdentity ?? "Unknown",
                    callerName: pendingIncomingPayload?.callerName,
                    hasVideo: pendingIncomingPayload?.hasVideo ?? false,
                    fromUri: pendingIncomingPayload?.fromUri,
                    toUri: pendingIncomingPayload?.toUri,
                    sipUri: pendingIncomingPayload?.sipUri
                )
                reportIncomingCall(payload: payload)
            } else {
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
            snapshot.callState = "calling"
            snapshot.message = message ?? "Outgoing call initialized"
            persistSnapshot()
            emitCallEvent(state: "calling", remoteIdentity: remoteIdentity, callId: snapshot.callId, message: snapshot.message)
        case LinphoneCallStateOutgoingProgress, LinphoneCallStateOutgoingRinging:
            snapshot.callState = "ringing"
            snapshot.message = message ?? "Outgoing call ringing"
            persistSnapshot()
            emitCallEvent(state: "ringing", remoteIdentity: remoteIdentity, callId: snapshot.callId, message: snapshot.message)
        case LinphoneCallStateConnected, LinphoneCallStateStreamsRunning:
            if let uuid = resolvedCallUUID(from: nil) {
                callKitManager.reportCallConnected(callUUID: uuid)
            }
            deferredAction = nil
            pendingIncomingPayload = nil
            snapshot.callState = "in_call"
            snapshot.message = message ?? "Call connected"
            persistSnapshot()
            emitCallEvent(state: "in_call", remoteIdentity: remoteIdentity, callId: snapshot.callId, message: snapshot.message)
        case LinphoneCallStateError:
            currentCall = nil
            let uuid = resolvedCallUUID(from: nil)
            if let uuid {
                callKitManager.reportCallEnded(callUUID: uuid, reason: .failed)
            }
            snapshot.callState = "failed"
            snapshot.message = message ?? "Call failed"
            persistSnapshot()
            emitCallEvent(state: "failed", remoteIdentity: remoteIdentity, callUUID: uuid?.uuidString, callId: snapshot.callId, message: snapshot.message)
            if let uuid {
                handleCallEnded(reason: .failed, callUUID: uuid, remoteIdentity: remoteIdentity)
            }
        case LinphoneCallStateEnd, LinphoneCallStateReleased:
            currentCall = nil
            let uuid = resolvedCallUUID(from: nil)
            if let uuid {
                callKitManager.reportCallEnded(callUUID: uuid, reason: .remoteEnded)
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
        default:
            break
        }
    }

    private func applyDeferredCallActionIfPossible() {
        guard let deferredAction else { return }
        switch deferredAction {
        case .answer:
            if acceptCall() {
                self.deferredAction = nil
            }
        case .decline:
            if declineCall() {
                self.deferredAction = nil
            }
        case .end:
            if hangup() {
                self.deferredAction = nil
            }
        }
    }

    private func reportIncomingCall(payload: VoIPIncomingPayload, completion: (() -> Void)? = nil) {
        pendingIncomingPayload = payload
        snapshot.callUUID = payload.uuid.uuidString
        snapshot.callId = payload.callId
        snapshot.callState = "incoming"
        snapshot.remoteIdentity = payload.handle
        snapshot.message = "Incoming VoIP push received"
        persistSnapshot()
        emitCallEvent(
            state: "incoming",
            remoteIdentity: payload.handle,
            callUUID: payload.uuid.uuidString,
            callId: payload.callId,
            message: "Incoming VoIP push received",
            extra: payload.toFlutterDictionary()
        )

        callKitManager.reportIncomingCall(payload: payload) { [weak self] error in
            defer { completion?() }
            guard let self else { return }

            if let error {
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
            }
        }
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
        let endedCallId = snapshot.callId
        snapshot.callUUID = nil
        snapshot.callId = nil
        snapshot.callState = "ended"
        snapshot.remoteIdentity = nil
        snapshot.message = endedMessage(for: reason)
        snapshot.muted = false
        snapshot.speakerOn = false
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
        if let encoded = try? JSONEncoder().encode(actions) {
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
        ])

        events([
            "type": "pending_call_actions",
            "actions": loadPendingCallActions().map { $0.toFlutterDictionary() },
        ])

        events([
            "type": "app_visibility",
            "appForeground": snapshot.appForeground,
            "callState": snapshot.callState,
            "remoteIdentity": snapshot.remoteIdentity as Any? ?? NSNull(),
        ])

        if let token = defaults.string(forKey: Constants.voipTokenKey), !token.isEmpty {
            events([
                "type": "push_token",
                "platform": "ios",
                "provider": "apns_voip",
                "pushType": "voip",
                "token": token,
            ])
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
    }

    func voipPushManagerDidInvalidateToken(_ manager: IOSVoIPPushManager) {
        defaults.removeObject(forKey: Constants.voipTokenKey)
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
        _ = restoreRegistrationIfNeeded()
        reportIncomingCall(payload: payload, completion: completion)
    }
}

extension IOSNativeSipManager: IOSCallKitManagerDelegate {
    func callKitManager(
        _ manager: IOSCallKitManager,
        didReceiveAnswerFor callUUID: UUID,
        payload: VoIPIncomingPayload?
    ) {
        snapshot.callUUID = callUUID.uuidString
        snapshot.callId = payload?.callId ?? snapshot.callId
        snapshot.callState = "ringing"
        snapshot.remoteIdentity = payload?.handle ?? snapshot.remoteIdentity
        snapshot.message = "System answer action received"
        persistSnapshot()
        emitCallActionEvent(action: "answer", callUUID: callUUID, payload: payload)
        if !acceptCall() {
            deferredAction = .answer
        }
    }

    func callKitManager(
        _ manager: IOSCallKitManager,
        didReceiveEndFor callUUID: UUID,
        payload: VoIPIncomingPayload?
    ) {
        let action = snapshot.callState == "incoming" ? "decline" : "end"
        emitCallActionEvent(action: action, callUUID: callUUID, payload: payload)
        if action == "decline" {
            if !declineCall() {
                deferredAction = .decline
            }
            handleCallEnded(
                reason: .unanswered,
                callUUID: callUUID,
                remoteIdentity: payload?.handle ?? snapshot.remoteIdentity
            )
        } else {
            if !hangup() {
                deferredAction = .end
            }
            handleCallEnded(
                reason: .remoteEnded,
                callUUID: callUUID,
                remoteIdentity: payload?.handle ?? snapshot.remoteIdentity
            )
        }
    }

    func callKitManagerDidActivateAudioSession(_ manager: IOSCallKitManager) {
        emit([
            "type": "audio_session",
            "state": "activated",
        ])
    }

    func callKitManagerDidDeactivateAudioSession(_ manager: IOSCallKitManager) {
        emit([
            "type": "audio_session",
            "state": "deactivated",
        ])
    }

    func callKitManagerDidReset(_ manager: IOSCallKitManager) {
        snapshot = NativeSipSnapshot.initial()
        persistSnapshot()
        emitCallEvent(state: "ended", message: "CallKit provider reset")
    }
}

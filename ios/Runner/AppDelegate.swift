import AVFAudio
import CallKit
import Flutter
import Network
import PushKit
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    // MARK: - Channels
    private var widgetMethodChannel: FlutterMethodChannel?
    private var networkEventChannel: FlutterEventChannel?
    private var networkEventSink: FlutterEventSink?
    private var nativeSipBridge: IOSNativeSipBridge?

    // MARK: - App Group
    private let appGroupId = "group.com.softtech.crmTaskManager"

    // MARK: - Network
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        setupWidgetMethodChannel(controller: controller)
        setupNetworkEventChannel(controller: controller)
        startNetworkMonitoring()
        nativeSipBridge = IOSNativeSipBridge(controller: controller)
        nativeSipBridge?.initializeRuntimeIfNeeded()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        nativeSipBridge?.updateAppVisibility(isForeground: true)
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        nativeSipBridge?.updateAppVisibility(isForeground: false)
    }

    // MARK: - MethodChannel
    private func setupWidgetMethodChannel(controller: FlutterViewController) {
        widgetMethodChannel = FlutterMethodChannel(
            name: "com.softtech.crm_task_manager/widget",
            binaryMessenger: controller.binaryMessenger
        )

        widgetMethodChannel?.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                result(false)
                return
            }

            switch call.method {
            case "syncPermissionsToWidget":
                self.handleSyncPermissions(call: call, result: result)
            case "syncLanguageToWidget":
                self.handleSyncLanguage(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - EventChannel
    private func setupNetworkEventChannel(controller: FlutterViewController) {
        networkEventChannel = FlutterEventChannel(
            name: "com.shamcrm/network_status",
            binaryMessenger: controller.binaryMessenger
        )
        networkEventChannel?.setStreamHandler(self)
    }

    // MARK: - Network monitoring
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied && !path.availableInterfaces.isEmpty
            self?.networkEventSink?(isConnected)
        }

        networkMonitor.start(queue: networkQueue)
    }

    // MARK: - Method handlers
    private func handleSyncPermissions(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let args = call.arguments as? [String: Any],
            let permissions = args["permissions"] as? [String]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            return
        }

        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            result(false)
            return
        }

        defaults.set(permissions, forKey: "user_permissions")
        WidgetCenter.shared.reloadAllTimelines()
        result(true)
    }

    private func handleSyncLanguage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let args = call.arguments as? [String: Any],
            let languageCode = args["languageCode"] as? String
        else {
            result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            return
        }

        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            result(false)
            return
        }

        defaults.set(languageCode, forKey: "app_language")
        WidgetCenter.shared.reloadAllTimelines()
        result(true)
    }

    // MARK: - Deep link
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        guard
            url.scheme == "shamcrm",
            url.host == "widget",
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let screen = components.queryItems?.first(where: { $0.name == "screen" })?.value
        else {
            return false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.widgetMethodChannel?.invokeMethod(
                "navigateFromWidget",
                arguments: ["screen": screen]
            )
        }

        return true
    }

    deinit {
        networkMonitor.cancel()
    }
}

// MARK: - FlutterStreamHandler
extension AppDelegate: FlutterStreamHandler {

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        networkEventSink = events

        let path = networkMonitor.currentPath
        let isConnected = path.status == .satisfied && !path.availableInterfaces.isEmpty

        events(isConnected)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        networkEventSink = nil
        return nil
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
            callUUID: nil
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
        ]
    }
}

private struct QueuedCallAction: Codable {
    let action: String
    let callUUID: String
    let handle: String?
    let callerName: String?
    let timestamp: TimeInterval

    func toFlutterDictionary() -> [String: Any] {
        [
            "action": action,
            "callUUID": callUUID,
            "remoteIdentity": handle ?? NSNull(),
            "callerName": callerName ?? NSNull(),
            "timestamp": timestamp,
        ]
    }
}

private struct VoIPIncomingPayload {
    let uuid: UUID
    let handle: String
    let callerName: String?
    let hasVideo: Bool

    static func from(userInfo: [AnyHashable: Any]) -> VoIPIncomingPayload {
        let dataDictionary = userInfo["data"] as? [String: Any]
        let callDictionary = userInfo["call"] as? [String: Any]
        let apsDictionary = userInfo["aps"] as? [String: Any]
        let alertDictionary = apsDictionary?["alert"] as? [String: Any]

        let rawUUID = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary],
            keys: ["uuid", "call_uuid", "callUUID", "call_id", "callId", "id"]
        )
        let uuid = UUID(uuidString: rawUUID ?? "") ?? UUID()

        let callerName = firstString(
            in: userInfo,
            nested: [dataDictionary, callDictionary, alertDictionary],
            keys: [
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
            nested: [dataDictionary, callDictionary],
            keys: [
                "handle",
                "remote_identity",
                "remoteIdentity",
                "number",
                "phone",
                "phone_number",
                "phoneNumber",
                "from",
                "from_number",
                "fromNumber",
            ]
        ) ?? callerName ?? "Unknown"

        let hasVideo = firstBool(
            in: userInfo,
            nested: [dataDictionary, callDictionary],
            keys: ["has_video", "hasVideo", "video", "is_video"]
        ) ?? false

        return VoIPIncomingPayload(
            uuid: uuid,
            handle: handle,
            callerName: callerName,
            hasVideo: hasVideo
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

private protocol IOSVoIPPushManagerDelegate: AnyObject {
    func voipPushManager(_ manager: IOSVoIPPushManager, didUpdate token: String)
    func voipPushManagerDidInvalidateToken(_ manager: IOSVoIPPushManager)
    func voipPushManager(
        _ manager: IOSVoIPPushManager,
        didReceiveIncoming payload: VoIPIncomingPayload,
        completion: @escaping () -> Void
    )
}

private final class IOSVoIPPushManager: NSObject, PKPushRegistryDelegate {
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

private protocol IOSCallKitManagerDelegate: AnyObject {
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

private final class IOSCallKitManager: NSObject, CXProviderDelegate {
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
        delegate?.callKitManager(
            self,
            didReceiveAnswerFor: action.callUUID,
            payload: payloadsByUUID[action.callUUID]
        )
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

private final class IOSNativeSipBridge: NSObject, FlutterStreamHandler {
    private enum Constants {
        static let methodChannelName = "com.shamcrm/native_sip/methods"
        static let eventChannelName = "com.shamcrm/native_sip/events"
        static let snapshotKey = "ios_native_sip_snapshot_v1"
        static let voipTokenKey = "ios_native_sip_voip_token"
        static let pendingCallActionsKey = "ios_native_sip_pending_call_actions_v1"
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

    init(controller: FlutterViewController) {
        methodChannel = FlutterMethodChannel(
            name: Constants.methodChannelName,
            binaryMessenger: controller.binaryMessenger
        )
        eventChannel = FlutterEventChannel(
            name: Constants.eventChannelName,
            binaryMessenger: controller.binaryMessenger
        )
        snapshot = IOSNativeSipBridge.loadSnapshot(from: UserDefaults.standard)

        super.init()

        eventChannel.setStreamHandler(self)
        methodChannel.setMethodCallHandler(handleMethodCall)
        voipPushManager.delegate = self
        callKitManager.delegate = self
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
                handle: (args["handle"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                    ? (args["handle"] as? String ?? "Unknown")
                    : "Unknown",
                callerName: args["callerName"] as? String,
                hasVideo: args["hasVideo"] as? Bool ?? false
            )
            reportIncomingCall(payload: payload)
            result(true)
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
            emitCallEvent(state: "in_call", message: "Call connected")
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
        case "register", "restoreRegistrationIfNeeded", "unregister", "makeCall", "acceptCall", "declineCall", "hangup", "setMuted", "setSpeaker":
            result(
                FlutterError(
                    code: "IOS_NATIVE_SIP_MEDIA_NOT_READY",
                    message: "iOS native SIP media path is not enabled yet. PushKit + CallKit foundation is active.",
                    details: call.method
                )
            )
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func reportIncomingCall(payload: VoIPIncomingPayload, completion: (() -> Void)? = nil) {
        snapshot.callUUID = payload.uuid.uuidString
        snapshot.callState = "incoming"
        snapshot.remoteIdentity = payload.handle
        snapshot.message = "Incoming VoIP push received"
        persistSnapshot()
        emitCallEvent(state: "incoming", remoteIdentity: payload.handle, callUUID: payload.uuid.uuidString, message: "Incoming VoIP push received")

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

    private func emitCallEvent(
        state: String,
        remoteIdentity: String? = nil,
        callUUID: String? = nil,
        message: String? = nil
    ) {
        emit([
            "type": "call",
            "state": state,
            "remoteIdentity": remoteIdentity ?? snapshot.remoteIdentity ?? NSNull(),
            "callUUID": callUUID ?? snapshot.callUUID ?? NSNull(),
            "message": message ?? snapshot.message ?? NSNull(),
            "muted": snapshot.muted,
            "speakerOn": snapshot.speakerOn,
        ])
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
            timestamp: Date().timeIntervalSince1970
        )

        var pending = loadPendingCallActions()
        pending.append(queuedAction)
        savePendingCallActions(pending)

        emit([
            "type": "call_action",
            "action": action,
            "callUUID": callUUID.uuidString,
            "remoteIdentity": payload?.handle ?? snapshot.remoteIdentity ?? NSNull(),
            "callerName": payload?.callerName ?? NSNull(),
            "timestamp": queuedAction.timestamp,
        ])
    }

    private func handleCallEnded(reason: CXCallEndedReason, callUUID: UUID, remoteIdentity: String?) {
        snapshot.callUUID = nil
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
            message: snapshot.message
        )

        emit([
            "type": "call_end_reason",
            "reason": endedReasonString(for: reason),
            "callUUID": callUUID.uuidString,
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
            "remoteIdentity": snapshot.remoteIdentity ?? NSNull(),
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

extension IOSNativeSipBridge: IOSVoIPPushManagerDelegate {
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
        reportIncomingCall(payload: payload, completion: completion)
    }
}

extension IOSNativeSipBridge: IOSCallKitManagerDelegate {
    func callKitManager(
        _ manager: IOSCallKitManager,
        didReceiveAnswerFor callUUID: UUID,
        payload: VoIPIncomingPayload?
    ) {
        snapshot.callUUID = callUUID.uuidString
        snapshot.callState = "ringing"
        snapshot.remoteIdentity = payload?.handle ?? snapshot.remoteIdentity
        snapshot.message = "System answer action received"
        persistSnapshot()
        emitCallActionEvent(action: "answer", callUUID: callUUID, payload: payload)
    }

    func callKitManager(
        _ manager: IOSCallKitManager,
        didReceiveEndFor callUUID: UUID,
        payload: VoIPIncomingPayload?
    ) {
        let action = snapshot.callState == "incoming" ? "decline" : "end"
        emitCallActionEvent(action: action, callUUID: callUUID, payload: payload)
        handleCallEnded(
            reason: action == "decline" ? .unanswered : .remoteEnded,
            callUUID: callUUID,
            remoteIdentity: payload?.handle ?? snapshot.remoteIdentity
        )
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

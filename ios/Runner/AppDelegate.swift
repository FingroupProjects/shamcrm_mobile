import FirebaseCore
import FirebaseMessaging
import Flutter
import Network
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    private var widgetMethodChannel: FlutterMethodChannel?
    private var networkEventChannel: FlutterEventChannel?
    private var networkEventSink: FlutterEventSink?
    private var nativeSipManager: IOSNativeSipManager?
    private var networkMethodChannel: FlutterMethodChannel?
    private var channelAttachAttempts = 0

    private let appGroupId = "group.com.softtech.crmTaskManager"
    private let pendingWidgetScreenKey = "flutter.pending_widget_screen"
    private let pendingPushKey = "ios_pending_push_tap_v1"
    private let chatReplyCategoryId = "CHAT_MESSAGE_REPLY"
    private let chatReplyActionId = "CHAT_REPLY"
    private let chatMarkReadActionId = "CHAT_MARK_READ"
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    // Токен Apple может прийти раньше, чем Dart вызовет Firebase.initializeApp.
    private var pendingApnsToken: Data?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)

        registerChatReplyNotificationCategory()
        startNetworkMonitoring()
        // firebase_messaging ждёт UIApplicationDidFinishLaunchingNotification,
        // но плагины регистрируются позже, уже в UIScene. Этот вызов он пропускает,
        // поэтому APNS-токен не появляется и FCM-токен остаётся пустым.
        registerForRemoteNotifications()

        return launched
    }

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        pendingApnsToken = deviceToken
        assignPendingApnsTokenIfPossible()
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NSLog("APNS registration failed: %@", error.localizedDescription)
        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    private func assignPendingApnsTokenIfPossible() {
        guard let token = pendingApnsToken else { return }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        Messaging.messaging().apnsToken = token
    }

    /// Flutter creates the implicit engine while connecting the UIScene.
    /// Register plugins and custom channels only after that engine is ready.
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        attachCustomChannels(messenger: engineBridge.applicationRegistrar.messenger())
        // Повторяем регистрацию после подключения плагинов: первый APNS-токен
        // мог прийти до инициализации Firebase.
        assignPendingApnsTokenIfPossible()
        registerForRemoteNotifications()
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        handleSceneDidBecomeActive()
    }

    func handleSceneDidBecomeActive() {
        // Safe to restore here: native skips REGISTER if the line is already up.
        nativeSipManager?.updateAppVisibility(isForeground: true, restoreRegistration: true)
        // После «Разрешить» сцена снова становится активной. Без повторной
        // регистрации Apple не присылает APNS-токен.
        registerForRemoteNotifications()
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        handleSceneDidEnterBackground()
        super.applicationDidEnterBackground(application)
    }

    func handleSceneDidEnterBackground() {
        nativeSipManager?.applicationDidEnterBackground()
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        handleSceneWillEnterForeground()
        super.applicationWillEnterForeground(application)
    }

    func handleSceneWillEnterForeground() {
        nativeSipManager?.applicationWillEnterForeground()
    }

    override func applicationWillResignActive(_ application: UIApplication) {
        handleSceneWillResignActive()
        super.applicationWillResignActive(application)
    }

    func handleSceneWillResignActive() {
        // Control Center, banners and system alerts fire this. Do not recreate
        // Linphone here — a REGISTER in Progress was being killed every time.
        nativeSipManager?.updateAppVisibility(isForeground: false, restoreRegistration: false)
    }

    private func attachCustomChannels(messenger providedMessenger: FlutterBinaryMessenger? = nil) {
        guard let messenger = providedMessenger ?? flutterMessenger() else {
            channelAttachAttempts += 1
            guard channelAttachAttempts < 10 else { return }
            DispatchQueue.main.async { [weak self] in
                self?.attachCustomChannels()
            }
            return
        }

        setupWidgetMethodChannel(messenger: messenger)
        setupNetworkEventChannel(messenger: messenger)
        setupNetworkMethodChannel(messenger: messenger)

        if nativeSipManager == nil {
            nativeSipManager = IOSNativeSipManager(messenger: messenger)
            nativeSipManager?.initializeRuntimeIfNeeded()
        }
    }

    private func flutterViewController() -> FlutterViewController? {
        findFlutterViewController(from: window?.rootViewController)
    }

    private func findFlutterViewController(from root: UIViewController?) -> FlutterViewController? {
        guard let root else { return nil }
        if let flutter = root as? FlutterViewController {
            return flutter
        }
        for child in root.children {
            if let found = findFlutterViewController(from: child) {
                return found
            }
        }
        return findFlutterViewController(from: root.presentedViewController)
    }

    private func flutterMessenger() -> FlutterBinaryMessenger? {
        if let controller = flutterViewController() {
            return controller.binaryMessenger
        }
        return registrar(forPlugin: "ShamCrmAppChannels")?.messenger()
    }

    private func setupWidgetMethodChannel(messenger: FlutterBinaryMessenger) {
        guard widgetMethodChannel == nil else { return }
        widgetMethodChannel = FlutterMethodChannel(
            name: "com.softtech.crm_task_manager/widget",
            binaryMessenger: messenger
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
            case "getPendingNavigation":
                self.handleGetPendingNavigation(result: result)
            case "getPendingPush":
                self.handleGetPendingPush(result: result)
            case "ackPendingPush":
                UserDefaults.standard.removeObject(forKey: self.pendingPushKey)
                result(true)
            case "showForegroundPush":
                self.handleShowForegroundPush(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Канал мог появиться позже, чем тап, которым открыли приложение.
        deliverPendingPush()
    }

    private func setupNetworkEventChannel(messenger: FlutterBinaryMessenger) {
        guard networkEventChannel == nil else { return }
        networkEventChannel = FlutterEventChannel(
            name: "com.shamcrm/network_status",
            binaryMessenger: messenger
        )
        networkEventChannel?.setStreamHandler(self)
    }

    private func setupNetworkMethodChannel(messenger: FlutterBinaryMessenger) {
        guard networkMethodChannel == nil else { return }
        networkMethodChannel = FlutterMethodChannel(
            name: "com.shamcrm/network_status/methods",
            binaryMessenger: messenger
        )
        networkMethodChannel?.setMethodCallHandler { call, result in
            if call.method == "isReady" {
                result(true)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func registerChatReplyNotificationCategory() {
        let replyAction = UNTextInputNotificationAction(
            identifier: chatReplyActionId,
            title: "Ответить",
            options: [],
            textInputButtonTitle: "Отправить",
            textInputPlaceholder: "Сообщение"
        )
        let markReadAction = UNNotificationAction(
            identifier: chatMarkReadActionId,
            title: "Пометить прочитанным",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: chatReplyCategoryId,
            actions: [replyAction, markReadAction],
            intentIdentifiers: [],
            options: []
        )

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.getNotificationCategories { categories in
            var updatedCategories = categories
            updatedCategories.insert(category)
            center.setNotificationCategories(updatedCategories)
        }
    }

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied && !path.availableInterfaces.isEmpty
            self?.networkEventSink?(isConnected)
        }

        networkMonitor.start(queue: networkQueue)
    }

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

    private func handleGetPendingNavigation(result: @escaping FlutterResult) {
        let screen = UserDefaults.standard.string(forKey: pendingWidgetScreenKey)
        UserDefaults.standard.removeObject(forKey: pendingWidgetScreenKey)
        result(screen)
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

    private func handleShowForegroundPush(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(false)
            return
        }

        let title = (args["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = (args["body"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let body, !body.isEmpty else {
            result(false)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = (title?.isEmpty == false ? title! : "shamCRM")
        content.body = body
        content.sound = .default
        // В баннер кладём все поля пуша, иначе тап по нему откроет
        // приложение без chat_id / event_id и экран некуда переходить.
        for (key, value) in args {
            if key == "title" || key == "body" {
                continue
            }
            let text = "\(value)".trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty, text.lowercased() != "null" {
                content.userInfo[key] = text
            }
        }

        let request = UNNotificationRequest(
            identifier: "foreground-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            result(error == nil)
        }
    }

    private func firstString(from userInfo: [AnyHashable: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = userInfo[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty, trimmed.lowercased() != "null" {
                    return trimmed
                }
            }
        }
        return nil
    }

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let type = firstString(from: notification.request.content.userInfo, keys: ["type", "event"])?
            .lowercased()
        if type == "incoming_call" || type == "call_start" || type == "sip_incoming_call" {
            completionHandler([])
            return
        }

        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == chatMarkReadActionId {
            let userInfo = response.notification.request.content.userInfo
            guard
                let chatId = resolveChatId(from: userInfo),
                let messageId = resolveMessageId(from: userInfo)
            else {
                completionHandler()
                return
            }

            markMessagesRead(chatId: chatId, messageId: messageId) {
                completionHandler()
            }
            return
        }

        guard response.actionIdentifier == chatReplyActionId else {
            // Обычный тап. Firebase на iOS часто не успевает забрать этот
            // payload: плагин поднимается уже после сцены. Сохраняем сами.
            capturePushTap(response.notification.request.content.userInfo)
            super.userNotificationCenter(
                center,
                didReceive: response,
                withCompletionHandler: completionHandler
            )
            return
        }

        guard let textResponse = response as? UNTextInputNotificationResponse else {
            completionHandler()
            return
        }

        let replyText = textResponse.userText.trimmingCharacters(in: .whitespacesAndNewlines)
        let userInfo = response.notification.request.content.userInfo
        guard !replyText.isEmpty, let chatId = resolveChatId(from: userInfo) else {
            completionHandler()
            return
        }

        sendQuickReply(chatId: chatId, message: replyText) {
            completionHandler()
        }
    }

    private func sendQuickReply(chatId: String, message: String, completion: @escaping () -> Void) {
        performChatPost(
            path: "/v2/chat/sendMessage/\(chatId)",
            body: ["message": message],
            completion: completion
        )
    }

    private func markMessagesRead(chatId: String, messageId: String, completion: @escaping () -> Void) {
        let parsedMessageId: Any = Int(messageId) ?? messageId
        performChatPost(
            path: "/v2/chat/readMessages/\(chatId)",
            body: ["up_to_message_id": parsedMessageId],
            completion: completion
        )
    }

    private func performChatPost(path: String, body: [String: Any], completion: @escaping () -> Void) {
        guard
            let baseUrl = resolveApiBaseUrl(),
            let token = readPreference("token"),
            !token.isEmpty
        else {
            completion()
            return
        }

        var components = URLComponents(string: "\(baseUrl)\(path)")
        var queryItems: [URLQueryItem] = []
        if let organizationId = readPreference("selectedOrganization"), isUsablePreference(organizationId) {
            queryItems.append(URLQueryItem(name: "organization_id", value: organizationId))
        }
        if let salesFunnelId = readPreference("selected_sales_funnel"), isUsablePreference(salesFunnelId) {
            queryItems.append(URLQueryItem(name: "sales_funnel_id", value: salesFunnelId))
        }
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else {
            completion()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("mobile", forHTTPHeaderField: "Device")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, _, _ in
            completion()
        }.resume()
    }

    private func resolveChatId(from userInfo: [AnyHashable: Any]) -> String? {
        let payload = flattenedPushValues(from: userInfo)
        return firstPushValue(payload, keys: ["chat_id", "chatId", "id"])
    }

    private func resolveMessageId(from userInfo: [AnyHashable: Any]) -> String? {
        let payload = flattenedPushValues(from: userInfo)
        return firstPushValue(
            payload,
            keys: ["message_id", "messageId", "notification_message_id", "up_to_message_id"]
        )
    }

    private func resolveApiBaseUrl() -> String? {
        if let verifiedDomain = readPreference("verifiedDomain"), isUsablePreference(verifiedDomain) {
            return "https://\(verifiedDomain)/api"
        }

        if
            let domain = readPreference("domain"),
            let mainDomain = readPreference("mainDomain"),
            isUsablePreference(domain),
            isUsablePreference(mainDomain)
        {
            return "https://\(domain)-back.\(mainDomain)/api"
        }

        if
            let enteredDomain = readPreference("enteredDomain"),
            let enteredMainDomain = readPreference("enteredMainDomain"),
            isUsablePreference(enteredDomain),
            isUsablePreference(enteredMainDomain)
        {
            let hostPrefix = enteredDomain.hasSuffix("-back") ? enteredDomain : "\(enteredDomain)-back"
            return "https://\(hostPrefix).\(enteredMainDomain)/api"
        }

        return nil
    }

    private func readPreference(_ key: String) -> String? {
        let defaults = UserDefaults.standard
        if let flutterValue = defaults.string(forKey: "flutter.\(key)"), !flutterValue.isEmpty {
            return flutterValue
        }
        return defaults.string(forKey: key)
    }

    private func isUsablePreference(_ value: String) -> Bool {
        !value.isEmpty && value != "null"
    }

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        handleOpenURL(url)
    }

    func handleOpenURL(_ url: URL) -> Bool {
        guard
            url.scheme == "shamcrm",
            url.host == "widget",
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let screen = components.queryItems?.first(where: { $0.name == "screen" })?.value
        else {
            return false
        }

        UserDefaults.standard.set(screen, forKey: pendingWidgetScreenKey)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.widgetMethodChannel?.invokeMethod(
                "navigateFromWidget",
                arguments: ["screen": screen]
            )
        }

        return true
    }

    /// Тап по пушу. Метод не private: его вызывает SceneDelegate при холодном запуске.
    func capturePushTap(_ userInfo: [AnyHashable: Any]) {
        var payload = flattenedPushValues(from: userInfo)
        if firstPushValue(payload, keys: ["type", "event"]) == nil {
            if firstPushValue(payload, keys: ["chat_id", "chatId"]) != nil {
                payload["type"] = "message"
            } else if firstPushValue(payload, keys: ["event_id", "notice_id"]) != nil {
                payload["type"] = "notice"
            } else {
                NSLog(
                    "Push tap has no type. keys=%@",
                    payload.keys.sorted().joined(separator: ",")
                )
                return
            }
        }

        let type = (payload["type"] ?? "").lowercased()
        if type == "incoming_call" ||
            type == "call_start" ||
            type == "sip_incoming_call" ||
            type == "call_cancelled" ||
            type == "call_canceled" ||
            type == "call_ended" ||
            type == "call_end" {
            return
        }

        NSLog("Push tap saved type=%@", payload["type"] ?? "")
        savePendingPush(payload)
        deliverPendingPush()
    }

    private func flattenedPushValues(from userInfo: [AnyHashable: Any]) -> [String: String] {
        var result: [String: String] = [:]

        func absorb(key: String, value: Any) {
            if key == "aps" {
                return
            }
            if let text = value as? String {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.lowercased() == "null" {
                    return
                }
                if trimmed.hasPrefix("{"),
                   let data = trimmed.data(using: .utf8),
                   let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    for (nestedKey, nestedValue) in object {
                        absorb(key: nestedKey, value: nestedValue)
                    }
                    return
                }
                result[key] = trimmed
                return
            }
            if let number = value as? NSNumber {
                result[key] = number.stringValue
                return
            }
            if let nested = value as? [AnyHashable: Any],
               key == "data" || key == "payload" || key == "custom" {
                for (nestedKey, nestedValue) in nested {
                    absorb(key: String(describing: nestedKey), value: nestedValue)
                }
            }
        }

        for (key, value) in userInfo {
            absorb(key: String(describing: key), value: value)
        }
        return result
    }

    private func firstPushValue(_ payload: [String: String], keys: [String]) -> String? {
        for key in keys {
            if let value = payload[key], !value.isEmpty, value.lowercased() != "null" {
                return value
            }
        }
        return nil
    }

    private func savePendingPush(_ payload: [String: String]) {
        var stored = payload
        stored["_saved_at_ms"] = String(Int(Date().timeIntervalSince1970 * 1000))
        guard
            let data = try? JSONSerialization.data(withJSONObject: stored),
            let json = String(data: data, encoding: .utf8)
        else {
            return
        }
        UserDefaults.standard.set(json, forKey: pendingPushKey)
    }

    private func pendingPushPayload() -> [String: String]? {
        guard let json = UserDefaults.standard.string(forKey: pendingPushKey),
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        let savedAt = Double("\(object["_saved_at_ms"] ?? "")") ?? 0
        if savedAt > 0, Date().timeIntervalSince1970 * 1000 - savedAt > 10 * 60 * 1000 {
            UserDefaults.standard.removeObject(forKey: pendingPushKey)
            return nil
        }

        var payload: [String: String] = [:]
        for (key, value) in object {
            if key == "_saved_at_ms" {
                continue
            }
            let text = "\(value)".trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty, text.lowercased() != "null" {
                payload[key] = text
            }
        }
        return payload.isEmpty ? nil : payload
    }

    private func deliverPendingPush() {
        guard let channel = widgetMethodChannel,
              let payload = pendingPushPayload()
        else {
            return
        }
        channel.invokeMethod("openFromPush", arguments: payload)
    }

    private func handleGetPendingPush(result: @escaping FlutterResult) {
        guard let payload = pendingPushPayload(),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8)
        else {
            result(nil)
            return
        }
        UserDefaults.standard.removeObject(forKey: pendingPushKey)
        result(json)
    }

    deinit {
        networkMonitor.cancel()
    }
}

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

import Flutter
import Network
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var widgetMethodChannel: FlutterMethodChannel?
    private var networkEventChannel: FlutterEventChannel?
    private var networkEventSink: FlutterEventSink?
    private var nativeSipManager: IOSNativeSipManager?

    private let appGroupId = "group.com.softtech.crmTaskManager"
    private let pendingWidgetScreenKey = "flutter.pending_widget_screen"
    private let chatReplyCategoryId = "CHAT_MESSAGE_REPLY"
    private let chatReplyActionId = "CHAT_REPLY"
    private let chatMarkReadActionId = "CHAT_MARK_READ"
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
        registerChatReplyNotificationCategory()
        nativeSipManager = IOSNativeSipManager(controller: controller)
        nativeSipManager?.initializeRuntimeIfNeeded()
        startNetworkMonitoring()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        nativeSipManager?.updateAppVisibility(isForeground: true)
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        nativeSipManager?.applicationDidEnterBackground()
        super.applicationDidEnterBackground(application)
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        nativeSipManager?.applicationWillEnterForeground()
        super.applicationWillEnterForeground(application)
    }

    override func applicationWillResignActive(_ application: UIApplication) {
        nativeSipManager?.updateAppVisibility(isForeground: false)
        super.applicationWillResignActive(application)
    }

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
            case "getPendingNavigation":
                self.handleGetPendingNavigation(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func setupNetworkEventChannel(controller: FlutterViewController) {
        networkEventChannel = FlutterEventChannel(
            name: "com.shamcrm/network_status",
            binaryMessenger: controller.binaryMessenger
        )
        networkEventChannel?.setStreamHandler(self)
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
        for key in ["chat_id", "chatId", "id"] {
            if let value = userInfo[key] {
                let stringValue = "\(value)".trimmingCharacters(in: .whitespacesAndNewlines)
                if isUsablePreference(stringValue) {
                    return stringValue
                }
            }
        }
        return nil
    }

    private func resolveMessageId(from userInfo: [AnyHashable: Any]) -> String? {
        for key in ["message_id", "messageId", "notification_message_id", "up_to_message_id"] {
            if let value = userInfo[key] {
                let stringValue = "\(value)".trimmingCharacters(in: .whitespacesAndNewlines)
                if isUsablePreference(stringValue) {
                    return stringValue
                }
            }
        }
        return nil
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

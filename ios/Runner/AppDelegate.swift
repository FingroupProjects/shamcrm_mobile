import UIKit
import Flutter
import WidgetKit
import Network

@main
@objc class AppDelegate: FlutterAppDelegate {

    // MARK: - Channels
    private var methodChannel: FlutterMethodChannel?
    private var networkEventChannel: FlutterEventChannel?
    private var networkEventSink: FlutterEventSink?

    // MARK: - App Group
    private let appGroupId = "group.com.softtech.crmTaskManager"

    // MARK: - Network
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")

    // MARK: - App lifecycle
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        setupMethodChannel(controller: controller)
        setupNetworkEventChannel(controller: controller)
        startNetworkMonitoring()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - MethodChannel
    private func setupMethodChannel(controller: FlutterViewController) {
        methodChannel = FlutterMethodChannel(
            name: "com.softtech.crm_task_manager/widget",
            binaryMessenger: controller.binaryMessenger
        )

        methodChannel?.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }

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
            let isConnected =
                path.status == .satisfied &&
                !path.availableInterfaces.isEmpty

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
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
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
            self?.methodChannel?.invokeMethod(
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
        let isConnected =
            path.status == .satisfied &&
            !path.availableInterfaces.isEmpty

        events(isConnected)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        networkEventSink = nil
        return nil
    }
}

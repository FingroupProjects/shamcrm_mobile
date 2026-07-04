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

    private let appGroupId = "group.com.softtech.avezov"
    private let pendingWidgetScreenKey = "flutter.pending_widget_screen"
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
            name: "com.softtech.avezov/widget",
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

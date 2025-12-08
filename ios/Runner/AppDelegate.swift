import UIKit
import Flutter
import WidgetKit
import Network // ✅ Для NWPathMonitor

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var methodChannel: FlutterMethodChannel?
    
    // App Group identifier for sharing data with widget
    private let appGroupId = "group.com.softtech.crmTaskManager"
    
    // ✅ НОВОЕ: Network Monitor
    private var networkMonitor: NWPathMonitor?
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    private var networkEventChannel: FlutterEventChannel?
    private var networkEventSink: FlutterEventSink?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Регистрация плагинов Flutter
        GeneratedPluginRegistrant.register(with: self)
        
        // Инициализация MethodChannel ПОСЛЕ регистрации плагинов
        if let controller = window?.rootViewController as? FlutterViewController {
            
            // ✅ ВАШ СУЩЕСТВУЮЩИЙ КОД (виджеты)
            methodChannel = FlutterMethodChannel(
                name: "com.softtech.crm_task_manager/widget",
                binaryMessenger: controller.binaryMessenger
            )
            
            methodChannel?.setMethodCallHandler { [weak self] (call, result) in
                switch call.method {
                case "syncPermissionsToWidget":
                    if let args = call.arguments as? [String: Any],
                       let permissions = args["permissions"] as? [String] {
                        self?.syncPermissionsToWidget(permissions: permissions)
                        result(true)
                    } else {
                        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                    }
                case "syncLanguageToWidget":
                    if let args = call.arguments as? [String: Any],
                       let languageCode = args["languageCode"] as? String {
                        self?.syncLanguageToWidget(languageCode: languageCode)
                        result(true)
                    } else {
                        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                    }
                default:
                    result(FlutterMethodNotImplemented)
                }
            }
            
            // ✅ НОВОЕ: Network Event Channel
            networkEventChannel = FlutterEventChannel(
                name: "com.shamcrm/network_status",
                binaryMessenger: controller.binaryMessenger
            )
            networkEventChannel?.setStreamHandler(self)
            
            print("✅ MethodChannel initialized (widget + network)")
        }
        
        // ✅ НОВОЕ: Запускаем network monitor
        startNetworkMonitoring()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - Network Monitoring (ПРОСТАЯ ЛОГИКА)
    private func startNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            // ✅ ПРОСТАЯ ПРОВЕРКА: Есть ли ХОТЬ ОДНО подключение?
            let hasAnyConnection = (path.status == .satisfied)
            
            print("🍎 iOS NetworkMonitor: status=\(path.status.rawValue), hasConnection=\(hasAnyConnection)")
            
            // ✅ ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: Есть ли хоть один интерфейс?
            let hasAnyInterface = path.availableInterfaces.count > 0
            
            if hasAnyInterface {
                print("🍎 Доступные интерфейсы: \(path.availableInterfaces.count)")
                for interface in path.availableInterfaces {
                    print("   - \(interface.name): \(interface.type)")
                }
            } else {
                print("🍎 ❌ Нет доступных интерфейсов")
            }
            
            // ✅ Показываем overlay ТОЛЬКО если нет ВООБЩЕ подключения
            // И нет доступных интерфейсов
            let shouldShowOverlay = !hasAnyConnection || !hasAnyInterface
            
            // Отправляем в Flutter (инвертируем, т.к. Flutter ожидает "isConnected")
            self?.networkEventSink?(!shouldShowOverlay)
        }
        
        networkMonitor?.start(queue: networkQueue)
        print("✅ iOS Network monitoring started")
    }
    
    // MARK: - ВАШ СУЩЕСТВУЮЩИЙ КОД (виджеты)
    
    private func syncPermissionsToWidget(permissions: [String]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }
        
        userDefaults.set(permissions, forKey: "user_permissions")
        userDefaults.synchronize()
        
        print("✅ Synced \(permissions.count) permissions to widget: \(permissions)")
        
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            print("✅ Widget timelines reloaded")
        }
    }
    
    private func syncLanguageToWidget(languageCode: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }
        
        userDefaults.set(languageCode, forKey: "app_language")
        userDefaults.synchronize()
        
        print("✅ Synced language to widget: \(languageCode)")
        
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            print("✅ Widget timelines reloaded for language change")
        }
    }
    
    // MARK: - Deep Link Handler (для виджета)
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        print("📱 iOS Deep link received: \(url.absoluteString)")
        
        guard url.scheme == "shamcrm",
              url.host == "widget" else {
            print("❌ Invalid URL scheme or host")
            return false
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            print("❌ No query parameters found")
            return false
        }
        
        var screenIdentifier: String?
        
        for item in queryItems {
            if item.name == "screen", let value = item.value {
                screenIdentifier = value
                print("📱 Parsed screen identifier: \(value)")
            }
        }
        
        if let screenIdentifier = screenIdentifier {
            if methodChannel == nil {
                if let controller = window?.rootViewController as? FlutterViewController {
                    methodChannel = FlutterMethodChannel(
                        name: "com.softtech.crm_task_manager/widget",
                        binaryMessenger: controller.binaryMessenger
                    )
                    print("✅ MethodChannel initialized in deep link handler")
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("✅ Sending to Flutter: screen=\(screenIdentifier)")
                self.methodChannel?.invokeMethod("navigateFromWidget", arguments: [
                    "screen": screenIdentifier
                ])
            }
            
            return true
        } else {
            print("❌ Missing screen parameter")
            return false
        }
    }
}

// ✅ НОВОЕ: FlutterStreamHandler для network events
extension AppDelegate: FlutterStreamHandler {
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        networkEventSink = events
        
        // Отправляем текущий статус сразу
        if let path = networkMonitor?.currentPath {
            let hasConnection = (path.status == .satisfied)
            let hasInterfaces = path.availableInterfaces.count > 0
            let isConnected = hasConnection && hasInterfaces
            
            events(isConnected)
            print("✅ iOS Network event sink attached, initial status: \(isConnected)")
        } else {
            // Если монитор еще не готов, предполагаем что интернет есть
            events(true)
            print("✅ iOS Network event sink attached, default status: true")
        }
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        networkEventSink = nil
        print("✅ iOS Network event sink detached")
        return nil
    }
}
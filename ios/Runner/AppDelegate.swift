import UIKit
import Flutter
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var methodChannel: FlutterMethodChannel?
    
    // App Group identifier for sharing data with widget
    private let appGroupId = "group.com.softtech.crmTaskManager"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Регистрация плагинов Flutter
        GeneratedPluginRegistrant.register(with: self)
        
        // Инициализация MethodChannel ПОСЛЕ регистрации плагинов
        if let controller = window?.rootViewController as? FlutterViewController {
            methodChannel = FlutterMethodChannel(
                name: "com.softtech.crm_task_manager/widget",
                binaryMessenger: controller.binaryMessenger
            )
            
            // Setup method call handler for syncing permissions to widget
            methodChannel?.setMethodCallHandler { [weak self] (call, result) in
                if call.method == "syncPermissionsToWidget" {
                    if let args = call.arguments as? [String: Any],
                       let permissions = args["permissions"] as? [String] {
                        self?.syncPermissionsToWidget(permissions: permissions)
                        result(true)
                    } else {
                        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                    }
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
            
            //print("✅ MethodChannel initialized")
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - Sync Permissions to Widget via App Groups
    private func syncPermissionsToWidget(permissions: [String]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }
        
        // Save permissions to shared UserDefaults
        userDefaults.set(permissions, forKey: "user_permissions")
        userDefaults.synchronize()
        
        print("✅ Synced \(permissions.count) permissions to widget: \(permissions)")
        
        // Reload widget timelines to reflect new permissions
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            print("✅ Widget timelines reloaded")
        }
    }
    
    // MARK: - Deep Link Handler (для виджета)
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        print("📱 iOS Deep link received: \(url.absoluteString)")
        
        // Парсим URL: shamcrm://widget?screen=dashboard
        guard url.scheme == "shamcrm",
              url.host == "widget" else {
            print("❌ Invalid URL scheme or host")
            return false
        }
        
        // Получаем параметры из query
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
        
        // Отправляем в Flutter
        if let screenIdentifier = screenIdentifier {
            // Убеждаемся, что methodChannel инициализирован
            if methodChannel == nil {
                // Если methodChannel еще не создан, инициализируем его
                if let controller = window?.rootViewController as? FlutterViewController {
                    methodChannel = FlutterMethodChannel(
                        name: "com.softtech.crm_task_manager/widget",
                        binaryMessenger: controller.binaryMessenger
                    )
                    print("✅ MethodChannel initialized in deep link handler")
                }
            }
            
            // Небольшая задержка, чтобы убедиться, что Flutter готов
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
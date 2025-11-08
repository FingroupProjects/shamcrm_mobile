import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var methodChannel: FlutterMethodChannel?
    
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
            print("✅ MethodChannel initialized")
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - Deep Link Handler (для виджета)
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        print("📱 iOS Deep link received: \(url.absoluteString)")
        
        // Парсим URL: shamcrm://widget?group=1&screen=0
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
        
        var group: Int?
        var screen: Int?
        
        for item in queryItems {
            if item.name == "group", let value = item.value {
                group = Int(value)
                print("📊 Parsed group: \(value)")
            }
            if item.name == "screen", let value = item.value {
                screen = Int(value)
                print("📱 Parsed screen: \(value)")
            }
        }
        
        // Отправляем в Flutter
        if let group = group, let screen = screen {
            print("✅ Sending to Flutter: group=\(group), screen=\(screen)")
            
            methodChannel?.invokeMethod("navigateFromWidget", arguments: [
                "group": group,
                "screenIndex": screen
            ])
            
            return true
        } else {
            print("❌ Missing group or screen parameter")
            return false
        }
    }
}
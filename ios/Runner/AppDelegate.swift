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
            //print("✅ MethodChannel initialized")
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - Deep Link Handler (для виджета)
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        //print("📱 iOS Deep link received: \(url.absoluteString)")
        
        // Парсим URL: shamcrm://widget?screen=dashboard
        guard url.scheme == "shamcrm",
              url.host == "widget" else {
            //print("❌ Invalid URL scheme or host")
            return false
        }
        
        // Получаем параметры из query
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            //print("❌ No query parameters found")
            return false
        }
        
        var screenIdentifier: String?
        
        for item in queryItems {
            if item.name == "screen", let value = item.value {
                screenIdentifier = value
                //print("📱 Parsed screen identifier: \(value)")
            }
        }
        
        // Отправляем в Flutter
        if let screenIdentifier = screenIdentifier {
            //print("✅ Sending to Flutter: screen=\(screenIdentifier)")
            
            methodChannel?.invokeMethod("navigateFromWidget", arguments: [
                "screen": screenIdentifier
            ])
            
            return true
        } else {
            //print("❌ Missing screen parameter")
            return false
        }
    }
}
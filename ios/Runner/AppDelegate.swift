import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}


// import UIKit
// import Flutter
// import BackgroundTasks

// @main
// @objc class AppDelegate: FlutterAppDelegate {
  
//   private let channel = FlutterMethodChannel(name: "com.shamcrm.bgTask", binaryMessenger: (window?.rootViewController as! FlutterViewController).binaryMessenger)

//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     // Регистрация плагинов Flutter
//     GeneratedPluginRegistrant.register(with: self)
    
//     // Обработка вызова метода с Flutter
//     channel.setMethodCallHandler { [weak self] (call, result) in
//         if call.method == "startBackgroundTask" {
//             self?.startBackgroundTask()
//             result("Фоновая задача запущена")
//         } else {
//             result(FlutterMethodNotImplemented)
//         }
//     }
    
//     // Регистрация задачи в BGTaskScheduler
//     BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.shamcrm.bgSyncTask", using: nil) { task in
//         self.handleBackgroundTask(task: task)
//     }
    
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }

//   // Метод для старта фоновой задачи
//   func startBackgroundTask() {
//       print("Запуск фоновой задачи")
//       // Здесь можно добавить логику для старта фоновой задачи
//   }

//   // Метод для обработки фонов задачи
//   func handleBackgroundTask(task: BGTask) {
//       print("Фоновая задача выполняется")
      
//       // Пример работы с задачей: уведомление о завершении задачи
//       task.setTaskCompleted(success: true)
//   }
// }

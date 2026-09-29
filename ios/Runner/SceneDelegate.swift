import Flutter
import UIKit

/// Owns the UI lifecycle required by iOS 27.
/// FlutterSceneDelegate keeps plugin lifecycle callbacks working on iOS 15+.
class SceneDelegate: FlutterSceneDelegate {
    private var appDelegate: AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }

    override func sceneDidBecomeActive(_ scene: UIScene) {
        super.sceneDidBecomeActive(scene)
        appDelegate?.handleSceneDidBecomeActive()
    }

    override func sceneWillResignActive(_ scene: UIScene) {
        appDelegate?.handleSceneWillResignActive()
        super.sceneWillResignActive(scene)
    }

    override func sceneWillEnterForeground(_ scene: UIScene) {
        super.sceneWillEnterForeground(scene)
        appDelegate?.handleSceneWillEnterForeground()
    }

    override func sceneDidEnterBackground(_ scene: UIScene) {
        appDelegate?.handleSceneDidEnterBackground()
        super.sceneDidEnterBackground(scene)
    }

    override func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        let handled = URLContexts.contains { appDelegate?.handleOpenURL($0.url) == true }
        if !handled {
            super.scene(scene, openURLContexts: URLContexts)
        }
    }
}

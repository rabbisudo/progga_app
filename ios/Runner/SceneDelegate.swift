import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    if #available(iOS 13.0, *) {
      self.window?.overrideUserInterfaceStyle = .light
    }
    self.window?.backgroundColor = UIColor.white
    self.window?.rootViewController?.view.backgroundColor = UIColor.white
  }
}

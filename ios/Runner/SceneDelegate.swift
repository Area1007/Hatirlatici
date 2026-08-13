import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else {
      super.scene(
        scene,
        willConnectTo: session,
        options: connectionOptions
      )
      return
    }

    let flutterViewController = FlutterViewController(
      project: nil,
      nibName: nil,
      bundle: nil
    )

    let appWindow = UIWindow(windowScene: windowScene)
    appWindow.rootViewController = flutterViewController
    self.window = appWindow
    appWindow.makeKeyAndVisible()

    super.scene(
      scene,
      willConnectTo: session,
      options: connectionOptions
    )
  }
}

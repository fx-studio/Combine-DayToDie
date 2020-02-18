//
//  SceneDelegate.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/18/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?


  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
    let window = UIWindow(windowScene: windowScene)
    
    let vc = LoginViewController()
    let navi = BaseNavigationController(rootViewController: vc)
    window.rootViewController = navi
    
    self.window = window
    window.makeKeyAndVisible()
  }

  func sceneDidDisconnect(_ scene: UIScene) {
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
  }

  func sceneWillResignActive(_ scene: UIScene) {
  }

  func sceneWillEnterForeground(_ scene: UIScene) {

  }

  func sceneDidEnterBackground(_ scene: UIScene) {
  }


}


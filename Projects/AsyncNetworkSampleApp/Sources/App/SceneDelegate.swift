//
//  SceneDelegate.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        
        // AppDependency 초기화
        let appDependency = AppDependency.shared
        
        // 메인 TabBarController 생성
        let tabBarController = MainTabBarController(appDependency: appDependency)
        
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        
        self.window = window
    }
}


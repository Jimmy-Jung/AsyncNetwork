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
        
        // URLCache.shared 크기 키우기 (ETag 캐싱 성능 향상)
        // - 모든 URLSession.shared가 이 캐시 사용
        // - HTTPClient() 생성 시 자동으로 큰 캐시 사용
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,   // 50MB (메모리)
            diskCapacity: 100 * 1024 * 1024     // 100MB (디스크)
        )
        
        let window = UIWindow(windowScene: windowScene)
        
        // AppDependency 초기화 (로깅 시스템 포함)
        let appDependency = AppDependency.shared
        
        // 메인 TabBarController 생성
        let tabBarController = MainTabBarController(appDependency: appDependency)
        
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        
        self.window = window
    }
}

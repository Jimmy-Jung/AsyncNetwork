//
//  MainTabBarController.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//  Updated by jimmy on 2026/01/11.
//

import UIKit

final class MainTabBarController: UITabBarController {
    private let appDependency: AppDependency

    init(appDependency: AppDependency) {
        self.appDependency = appDependency
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupAppearance()
    }

    private func setupViewControllers() {
        // API Playground 탭 (SwiftUI - DocKit 스타일)
        let apiPlaygroundSwiftVC = APIPlaygroundSwiftViewController(networkService: appDependency.networkService)
        apiPlaygroundSwiftVC.title = "API Playground"
        apiPlaygroundSwiftVC.tabBarItem = UITabBarItem(
            title: "Playground",
            image: UIImage(systemName: "hammer.fill"),
            selectedImage: nil
        )

        viewControllers = [
            apiPlaygroundSwiftVC  // SwiftUI는 이미 NavigationStack이 내장되어 있음
        ]
        
        // 탭바 숨김 (탭이 1개만 있으므로)
        tabBar.isHidden = true
    }

    private func setupAppearance() {
        tabBar.tintColor = .systemBlue
    }
}

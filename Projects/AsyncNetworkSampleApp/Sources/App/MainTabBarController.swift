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
        let apiPlaygroundVC = APIPlaygroundViewController(networkService: appDependency.networkService)
        apiPlaygroundVC.title = "API Playground"
        apiPlaygroundVC.tabBarItem = UITabBarItem(
            title: "Playground",
            image: UIImage(systemName: "hammer.fill"),
            selectedImage: nil
        )

        // Request Interceptors 탭 (SwiftUI)
        // InterceptorsViewModel 사용 (분리됨)
        let interceptorsViewModel = InterceptorsViewModel(
            runtimeInterceptorManager: appDependency.runtimeInterceptorManager
        )
        let interceptorsVC = InterceptorsViewController(viewModel: interceptorsViewModel)
        interceptorsVC.title = "Interceptors"
        interceptorsVC.tabBarItem = UITabBarItem(
            title: "Interceptors",
            image: UIImage(systemName: "link.circle"),
            selectedImage: UIImage(systemName: "link.circle.fill")
        )

        viewControllers = [
            apiPlaygroundVC,
            interceptorsVC
        ]

        // 탭바 표시 (2개 이상의 탭이 있음)
        tabBar.isHidden = false
    }

    private func setupAppearance() {
        tabBar.tintColor = .systemBlue
    }
}

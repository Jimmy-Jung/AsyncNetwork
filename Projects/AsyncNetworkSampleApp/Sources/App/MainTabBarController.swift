//
//  MainTabBarController.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
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
        // Posts Tab
        let postListViewModel = PostListViewModel(getPostsUseCase: appDependency.getPostsUseCase)
        let postsVC = PostListViewController(viewModel: postListViewModel)
        postsVC.title = "게시글"
        postsVC.tabBarItem = UITabBarItem(title: "게시글", image: UIImage(systemName: "doc.text"), selectedImage: nil)

        // Users Tab
        let userListViewModel = UserListViewModel(getUsersUseCase: appDependency.getUsersUseCase)
        let usersVC = UserListViewController(viewModel: userListViewModel)
        usersVC.title = "사용자"
        usersVC.tabBarItem = UITabBarItem(title: "사용자", image: UIImage(systemName: "person.2"), selectedImage: nil)

        // Albums Tab
        let albumListViewModel = AlbumListViewModel(userId: 1, getAlbumsUseCase: appDependency.getAlbumsUseCase)
        let albumsVC = AlbumListViewController(viewModel: albumListViewModel)
        albumsVC.title = "앨범"
        albumsVC.tabBarItem = UITabBarItem(
            title: "앨범",
            image: UIImage(systemName: "photo.on.rectangle"),
            selectedImage: nil
        )

        // Settings Tab
        let settingsViewModel = SettingsViewModel()
        let settingsVC = SettingsViewController(viewModel: settingsViewModel)
        settingsVC.title = "설정"
        settingsVC.tabBarItem = UITabBarItem(title: "설정", image: UIImage(systemName: "gear"), selectedImage: nil)

        viewControllers = [
            UINavigationController(rootViewController: postsVC),
            UINavigationController(rootViewController: usersVC),
            UINavigationController(rootViewController: albumsVC),
            UINavigationController(rootViewController: settingsVC)
        ]
    }

    private func setupAppearance() {
        tabBar.tintColor = .systemBlue
    }

    private func createPlaceholderViewController(
        title: String,
        systemImage: String
    ) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        viewController.title = title
        viewController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: systemImage),
            selectedImage: nil
        )

        let label = UILabel()
        label.text = "\(title)\n준비 중입니다..."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .title1)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false

        viewController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])

        return viewController
    }
}

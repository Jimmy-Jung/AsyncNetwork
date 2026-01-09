//
//  AppDependency.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import AsyncViewModel
import Foundation

/// 앱 전역 의존성 컨테이너
@MainActor
final class AppDependency: ObservableObject {
    static let shared = AppDependency()
    
    // MARK: - Network
    
    let networkService: NetworkService
    
    // MARK: - Repositories
    
    let postRepository: PostRepository
    let userRepository: UserRepository
    let commentRepository: CommentRepository
    let albumRepository: AlbumRepository
    
    // MARK: - Use Cases
    
    let getPostsUseCase: GetPostsUseCase
    let createPostUseCase: CreatePostUseCase
    let getUsersUseCase: GetUsersUseCase
    let getAlbumsUseCase: GetAlbumsUseCase
    
    // MARK: - Initialization
    
    private init() {
        // NetworkService 초기화
        self.networkService = NetworkService(
            configuration: .development,
            plugins: [
                ConsoleLoggingInterceptor(minimumLevel: .verbose)
            ]
        )
        
        ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withFormat(.compact)
            .withMinimumLevel(.verbose)
            .withStateDiffOnly(false)
            .withGroupEffects(false)
            .withZeroPerformance(true)
            .buildAsShared()
        
        // Repositories 초기화
        self.postRepository = PostRepositoryImpl(networkService: networkService)
        self.userRepository = UserRepositoryImpl(networkService: networkService)
        self.commentRepository = CommentRepositoryImpl(networkService: networkService)
        self.albumRepository = AlbumRepositoryImpl(networkService: networkService)
        
        // Use Cases 초기화
        self.getPostsUseCase = GetPostsUseCase(repository: postRepository)
        self.createPostUseCase = CreatePostUseCase(repository: postRepository)
        self.getUsersUseCase = GetUsersUseCase(repository: userRepository)
        self.getAlbumsUseCase = GetAlbumsUseCase(repository: albumRepository)
    }
}


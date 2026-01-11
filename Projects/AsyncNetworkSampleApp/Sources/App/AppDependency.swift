//
//  AppDependency.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import AsyncViewModel
import Foundation
import TraceKit

/// 앱 전역 의존성 컨테이너
@MainActor
final class AppDependency: ObservableObject {
    static let shared = AppDependency()
    
    // MARK: - Network
    
    /// 일반 API 요청용 NetworkService (ETag 기반 캐시)
    /// - ETag 조건부 요청으로 서버 데이터 변경 감지
    /// - 데이터 변경 없으면 304 Not Modified 응답 (네트워크 절약)
    /// - HTTP 표준 방식
    /// - Verbose 로깅
    let networkService: NetworkService
    
    /// 동적 로깅 레벨 제어를 위한 Interceptor
    let loggingInterceptor: DynamicLoggingInterceptor
    
    /// ETag 기반 캐시 Interceptor
    let etagInterceptor: ETagInterceptor
    
    // MARK: - Repositories
    
    let postRepository: PostRepository
    let userRepository: UserRepository
    let commentRepository: CommentRepository
    let albumRepository: AlbumRepository
    let githubRepository: GitHubRepository
    
    // MARK: - Use Cases
    
    let getPostsUseCase: GetPostsUseCase
    let createPostUseCase: CreatePostUseCase
    let getUsersUseCase: GetUsersUseCase
    let getAlbumsUseCase: GetAlbumsUseCase
    let getGitHubUserUseCase: GetGitHubUserUseCase
    
    // MARK: - Initialization
    
    private init() {
        // Interceptor 초기화
        self.loggingInterceptor = DynamicLoggingInterceptor(initialLevel: .verbose)
        self.etagInterceptor = ETagInterceptor()
        
        // HTTPClient 생성
        let httpClient = HTTPClient()
        
        // NetworkService 초기화
        // - ETagInterceptor: 서버 데이터 변경 감지
        // - DynamicLoggingInterceptor: 로그 레벨 동적 제어
        self.networkService = NetworkService(
            httpClient: httpClient,
            retryPolicy: RetryPolicy(configuration: .patient),
            interceptors: [etagInterceptor, loggingInterceptor]
        )
        
        // Repositories 초기화
        self.postRepository = PostRepositoryImpl(networkService: networkService)
        self.userRepository = UserRepositoryImpl(networkService: networkService)
        self.commentRepository = CommentRepositoryImpl(networkService: networkService)
        self.albumRepository = AlbumRepositoryImpl(networkService: networkService)
        self.githubRepository = GitHubRepositoryImpl(networkService: networkService)
        
        // Use Cases 초기화
        self.getPostsUseCase = GetPostsUseCase(repository: postRepository)
        self.createPostUseCase = CreatePostUseCase(repository: postRepository)
        self.getUsersUseCase = GetUsersUseCase(repository: userRepository)
        self.getAlbumsUseCase = GetAlbumsUseCase(repository: albumRepository)
        self.getGitHubUserUseCase = GetGitHubUserUseCase(repository: githubRepository)
        
        // 모든 프로퍼티 초기화 후 로깅 시스템 초기화
        setupLogging()
    }
    
    // MARK: - Private Methods
    
    /// 로깅 시스템을 초기화합니다 (TraceKit + AsyncViewModel Logger)
    private func setupLogging() {
        // TraceKit 초기화 (비동기)
        Task {
            await initializeTraceKit()
        }
        
        // AsyncViewModel Logger 설정 (동기)
        ViewModelLoggerBuilder()
            .addLogger(TraceKitViewModelLogger())
            .withFormat(.compact)
            .withMinimumLevel(.info)
            .withStateDiffOnly(true)
            .withGroupEffects(true)
            .buildAsShared()
    }
    
    @TraceKitActor
    private func initializeTraceKit() async {
        await TraceKitBuilder()
            .addOSLog(
                subsystem: Bundle.main.bundleIdentifier ?? "com.asyncnetwork.sample",
                minLevel: .verbose,
                formatter: PrettyTraceFormatter.standard
            )
            .with(configuration: .debug)
            .withDefaultSanitizer()
            .applyLaunchArguments()
            .buildAsShared()
        
        await TraceKit.async.info("✅ TraceKit initialized successfully")
    }
    
    // MARK: - Public Methods
    
    /// 네트워크 로그 레벨을 설정합니다
    func setNetworkLogLevel(_ level: NetworkLogLevel) {
        Task {
            await loggingInterceptor.setLevel(level)
        }
    }
}


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

    // MARK: - Settings

    /// 현재 선택된 Retry Policy Preset
    @Published var currentRetryPolicyPreset: RetryPolicyPreset = .patient

    // MARK: - Network

    /// NetworkMonitor (Infrastructure Layer)
    /// - 순수 네트워크 상태 감지
    /// - NetworkService에서 네트워크 연결 상태 확인 용도
    let networkMonitor: NetworkMonitor
    
    /// NetworkMonitoringService (Presentation/Services)
    /// - UI 레이어에서 네트워크 상태 관찰 용도
    /// - ObservableObject로 SwiftUI와 통합
    let networkMonitoringService: DefaultNetworkMonitoringService
    
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

    /// 런타임 인터셉터 관리자
    let runtimeInterceptorManager: RuntimeInterceptorManager

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
        // NetworkMonitor 초기화 (Infrastructure Layer)
        networkMonitor = NetworkMonitor.shared
        
        // NetworkMonitoringService 초기화 (Presentation/Services)
        networkMonitoringService = DefaultNetworkMonitoringService(monitor: networkMonitor)
        
        // Interceptor 초기화
        loggingInterceptor = DynamicLoggingInterceptor(initialLevel: .verbose)
        etagInterceptor = ETagInterceptor()

        // RuntimeInterceptorManager 초기화 (loggingInterceptor, etagInterceptor 주입)
        runtimeInterceptorManager = RuntimeInterceptorManager(
            loggingInterceptor: loggingInterceptor,
            etagInterceptor: etagInterceptor
        )

        // HTTPClient 생성
        let httpClient = HTTPClient()

        // NetworkService 초기화
        // - RuntimeInterceptorWrapper: 모든 인터셉터를 런타임에 동적으로 관리
        //   (etag, logging, auth, customHeader, timestamp 모두 포함)
        networkService = NetworkService(
            httpClient: httpClient,
            retryPolicy: RetryPolicy(configuration: .patient),
            interceptors: [
                RuntimeInterceptorWrapper(manager: runtimeInterceptorManager)
            ]
        )

        // Repositories 초기화
        postRepository = PostRepositoryImpl(networkService: networkService)
        userRepository = UserRepositoryImpl(networkService: networkService)
        commentRepository = CommentRepositoryImpl(networkService: networkService)
        albumRepository = AlbumRepositoryImpl(networkService: networkService)
        githubRepository = GitHubRepositoryImpl(networkService: networkService)

        // Use Cases 초기화
        getPostsUseCase = GetPostsUseCase(repository: postRepository)
        createPostUseCase = CreatePostUseCase(repository: postRepository)
        getUsersUseCase = GetUsersUseCase(repository: userRepository)
        getAlbumsUseCase = GetAlbumsUseCase(repository: albumRepository)
        getGitHubUserUseCase = GetGitHubUserUseCase(repository: githubRepository)

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

//
//  AsyncNetworkExampleApp.swift
//  AsyncNetworkExample
//
//  Created by jimmy on 2025/12/29.
//

import AsyncNetwork
import AsyncViewModel
import SwiftUI
import TraceKit

@main
struct AsyncNetworkExampleApp: App {
    let repository: APITestRepository

    init() {
        // Logging Interceptor 생성
        let loggingInterceptor = TraceKitLoggingInterceptor(
            minimumLevel: .verbose,
            sensitiveKeys: ["password", "token", "key", "secret"]
        )

        let processor = ResponseProcessor(
            steps: [StatusCodeValidationStep()]
        )

        let networkService = NetworkService(
            httpClient: HTTPClient(),
            retryPolicy: .default,
            configuration: .development,
            responseProcessor: processor,
            interceptors: [loggingInterceptor] // Interceptor 주입
        )

        repository = DefaultAPITestRepository(networkService: networkService)
    }

    var body: some Scene {
        WindowGroup {
            RootView(repository: repository)
                .task {
                    await initializeTraceKit()
                    configureAsyncViewModelLogger()
                }
        }
    }

    @TraceKitActor
    private func initializeTraceKit() async {
        await TraceKitBuilder()
            .addOSLog(
                subsystem: Bundle.main.bundleIdentifier ?? "com.jimmy.AsyncNetworkExample",
                minLevel: .verbose,
                formatter: PrettyTraceFormatter.standard
            )
            .with(configuration: .debug)
            .withDefaultSanitizer()
            .applyLaunchArguments()
            .buildAsShared()

        await TraceKit.async.info("✅ TraceKit initialized successfully (OSLog)")
    }

    private func configureAsyncViewModelLogger() {
        ViewModelLoggerBuilder()
            .addLogger(TraceKitViewModelLogger())
            .withFormat(.compact)
            .withMinimumLevel(.verbose)
            .withStateDiffOnly(true)
            .withGroupEffects(true)
            .buildAsShared()

        TraceKit.info("✅ AsyncViewModel logger configured with builder pattern")
    }
}

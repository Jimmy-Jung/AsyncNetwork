//
//  HTTPClient.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - HTTPClient

/// 순수한 HTTP 통신만 담당하는 클라이언트
///
/// **단일 책임:**
/// - HTTP 요청/응답 처리
/// - URLSession을 통한 네트워크 통신
/// - 로거 주입 지원 (의존성 역전)
///
/// **사용 예시:**
/// ```swift
/// // 기본 사용 (ConsoleLogger)
/// let client = HTTPClient()
///
/// // TraceKit 로거 주입
/// let client = HTTPClient(logger: TraceKitNetworkLogger())
///
/// // 로깅 비활성화
/// let client = HTTPClient(logger: SilentNetworkLogger())
/// ```
public struct HTTPClient: Sendable {
    // MARK: - Properties

    private let session: URLSession
    private let logger: NetworkLogger?

    // MARK: - Initialization

    public init(
        session: URLSession = .shared,
        logger: NetworkLogger? = ConsoleNetworkLogger()
    ) {
        self.session = session
        self.logger = logger
    }

    public init(
        configuration: NetworkConfiguration,
        logger: NetworkLogger? = nil
    ) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout

        session = URLSession(configuration: sessionConfig)
        self.logger = logger ?? (configuration.enableLogging ? ConsoleNetworkLogger() : nil)
    }

    // MARK: - Public Methods

    /// APIRequest 실행 (편의 메서드)
    /// - Parameter request: 실행할 API 요청
    /// - Returns: HTTPResponse 객체
    /// - Throws: NetworkError
    public func request(_ request: any APIRequest) async throws -> HTTPResponse {
        let urlRequest = try request.asURLRequest()
        return try await self.request(urlRequest)
    }

    /// URLRequest 직접 실행
    /// - Parameter urlRequest: 실행할 URLRequest
    /// - Returns: HTTPResponse 객체
    /// - Throws: NetworkError
    public func request(_ urlRequest: URLRequest) async throws -> HTTPResponse {
        // 요청 로깅
        logger?.logRequest(urlRequest, level: .debug)

        let startTime = Date()

        do {
            let (data, response) = try await session.data(for: urlRequest)
            let httpResponse = try HTTPResponse.from(data: data, response: response, request: urlRequest)

            let duration = Date().timeIntervalSince(startTime)

            // 응답 로깅
            if let urlResponse = response as? HTTPURLResponse {
                let level: NetworkLogLevel = httpResponse.statusCode < 400 ? .debug : .warning
                logger?.logResponse(urlResponse, data: data, duration: duration, level: level)
            }

            return httpResponse
        } catch {
            // 에러 로깅
            logger?.logError(error, request: urlRequest, level: .error)
            throw error
        }
    }
}

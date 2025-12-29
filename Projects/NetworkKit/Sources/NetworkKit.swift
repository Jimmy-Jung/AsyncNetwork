import Foundation

// MARK: - NetworkKit

/// NetworkKit 네임스페이스
public enum NetworkKit {
    /// NetworkKit 버전
    public static let version = "1.0.0"
}

// MARK: - Service Factory

public extension NetworkKit {
    /// NetworkService 생성
    ///
    /// - Parameters:
    ///   - logger: 네트워크 로거 (기본값: ConsoleNetworkLogger)
    ///   - configuration: 네트워크 설정 (기본값: .development)
    /// - Returns: NetworkService 인스턴스
    static func createNetworkService(
        logger: NetworkLogger = ConsoleNetworkLogger(),
        configuration: NetworkConfiguration = .development
    ) -> NetworkService {
        let httpClient = HTTPClient(logger: logger)
        let retryPolicy = RetryPolicy()
        let responseProcessor = ResponseProcessor()
        let dataResponseProcessor = DataResponseProcessor()

        return NetworkService(
            httpClient: httpClient,
            retryPolicy: retryPolicy,
            configuration: configuration,
            responseProcessor: responseProcessor,
            dataResponseProcessor: dataResponseProcessor
        )
    }
}

// MARK: - Test Helpers

#if DEBUG
    public extension NetworkKit {
        /// 테스트용 NetworkService 생성
        ///
        /// - Parameters:
        ///   - httpClient: 커스텀 HTTP 클라이언트
        ///   - retryPolicy: 재시도 정책
        ///   - configuration: 네트워크 설정
        ///   - responseProcessor: 응답 프로세서
        /// - Returns: 테스트용 NetworkService
        static func createTestNetworkService(
            httpClient: HTTPClient? = nil,
            retryPolicy: RetryPolicy? = nil,
            configuration: NetworkConfiguration = .development,
            responseProcessor: (any ResponseProcessing)? = nil,
            dataResponseProcessor: (any DataResponseProcessing)? = nil,
            logger: NetworkLogger = SilentNetworkLogger()
        ) -> NetworkService {
            let client = httpClient ?? HTTPClient(logger: logger)
            let policy = retryPolicy ?? RetryPolicy()
            let processor = responseProcessor ?? ResponseProcessor()
            let dataProcessor = dataResponseProcessor ?? DataResponseProcessor()

            return NetworkService(
                httpClient: client,
                retryPolicy: policy,
                configuration: configuration,
                responseProcessor: processor,
                dataResponseProcessor: dataProcessor
            )
        }
    }
#endif

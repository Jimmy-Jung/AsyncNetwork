import Foundation

public enum NetworkKit {
    public static let version = "1.0.0"
}

// MARK: - Service Factory

public extension NetworkKit {
    /// NetworkService 생성
    ///
    /// - Parameters:
    ///   - interceptors: Request Interceptors (기본값: ConsoleLoggingInterceptor)
    ///   - configuration: 네트워크 설정 (기본값: .development)
    /// - Returns: NetworkService 인스턴스
    static func createNetworkService(
        interceptors: [any RequestInterceptor] = [ConsoleLoggingInterceptor()],
        configuration: NetworkConfiguration = .development
    ) -> NetworkService {
        let httpClient = HTTPClient()
        let retryPolicy = RetryPolicy()
        let responseProcessor = ResponseProcessor()
        let dataResponseProcessor = DataResponseProcessor()

        return NetworkService(
            httpClient: httpClient,
            retryPolicy: retryPolicy,
            configuration: configuration,
            responseProcessor: responseProcessor,
            dataResponseProcessor: dataResponseProcessor,
            interceptors: interceptors
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
        ///   - interceptors: Request Interceptors (기본값: 빈 배열)
        /// - Returns: 테스트용 NetworkService
        static func createTestNetworkService(
            httpClient: HTTPClient? = nil,
            retryPolicy: RetryPolicy? = nil,
            configuration: NetworkConfiguration = .development,
            responseProcessor: (any ResponseProcessing)? = nil,
            dataResponseProcessor: (any DataResponseProcessing)? = nil,
            interceptors: [any RequestInterceptor] = []
        ) -> NetworkService {
            let client = httpClient ?? HTTPClient()
            let policy = retryPolicy ?? RetryPolicy()
            let processor = responseProcessor ?? ResponseProcessor()
            let dataProcessor = dataResponseProcessor ?? DataResponseProcessor()

            return NetworkService(
                httpClient: client,
                retryPolicy: policy,
                configuration: configuration,
                responseProcessor: processor,
                dataResponseProcessor: dataProcessor,
                interceptors: interceptors
            )
        }
    }
#endif

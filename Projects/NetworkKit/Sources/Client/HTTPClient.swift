import Foundation

/// HTTP 통신 클라이언트
///
/// **사용 예시:**
/// ```swift
/// // 기본 사용
/// let client = HTTPClient()
///
/// // 커스텀 URLSession
/// let client = HTTPClient(session: customSession)
///
/// // NetworkConfiguration 사용
/// let client = HTTPClient(configuration: .production)
/// ```
public struct HTTPClient: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public init(configuration: NetworkConfiguration) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout

        self.session = URLSession(configuration: sessionConfig)
    }

    public func request(_ request: any APIRequest) async throws -> HTTPResponse {
        let urlRequest = try request.asURLRequest()
        return try await self.request(urlRequest)
    }

    public func request(_ urlRequest: URLRequest) async throws -> HTTPResponse {
        let (data, response) = try await session.data(for: urlRequest)
        return try HTTPResponse.from(data: data, response: response, request: urlRequest)
    }
}

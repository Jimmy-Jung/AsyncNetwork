//
//  HTTPClient.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

/// HTTP 클라이언트 프로토콜
///
/// 네트워크 요청을 수행하는 클라이언트의 인터페이스를 정의합니다.
/// 테스트 시 Mock 구현체를 주입하여 사용할 수 있습니다.
public protocol HTTPClientProtocol: Sendable {
    func request(_ request: any APIRequest) async throws -> HTTPResponse
    func request(_ urlRequest: URLRequest) async throws -> HTTPResponse
}

/// HTTP 통신 클라이언트 (기본 구현)
public struct HTTPClient: HTTPClientProtocol {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public init(configuration: NetworkConfiguration) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout

        session = URLSession(configuration: sessionConfig)
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

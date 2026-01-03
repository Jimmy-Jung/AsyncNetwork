//
//  MockURLProtocol.swift
//  NetworkKitTests
//
//  Created by jimmy on 2025/12/29.
//

@preconcurrency import Foundation

/// ✅ URLProtocol을 Sendable로 만들어서 Task에서 사용 가능하게 함
/// 테스트 헬퍼이므로 @unchecked Sendable 사용이 허용됨
extension URLProtocol: @unchecked @retroactive Sendable {}

/// Mock 라우트를 관리하는 Actor
///
/// Swift 6 strict concurrency를 준수하며, nonisolated(unsafe) 대신 Actor를 사용합니다.
actor MockURLProtocolRegistry {
    // ✅ 동기 함수로 유지 (URLProtocol은 동기 컨텍스트에서 실행됨)
    typealias RequestHandler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    private var routes: [String: RequestHandler] = [:]

    func register(path: String, handler: @escaping RequestHandler) {
        routes[path] = handler
    }

    func getHandler(for path: String) -> RequestHandler? {
        routes[path]
    }

    func clear() {
        routes.removeAll()
    }
}

class MockURLProtocol: URLProtocol, @unchecked Sendable {
    // MARK: - Properties

    /// Swift Concurrency 안전한 레지스트리
    static let registry = MockURLProtocolRegistry()

    // MARK: - Helper Methods

    static func register(path: String, handler: @escaping MockURLProtocolRegistry.RequestHandler) async {
        await registry.register(path: path, handler: handler)
    }

    static func clear() async {
        await registry.clear()
    }

    // MARK: - URLProtocol Overrides

    override class func canInit(with _: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        // ✅ @preconcurrency import로 URLProtocol을 concurrency-safe하게 처리
        let localClient = client
        let localRequest = request
        // URL.path는 항상 "/"로 시작하므로 그대로 사용
        let localPath = url.path
        let localSelf = self

        Task {
            guard let handler = await MockURLProtocol.registry.getHandler(for: localPath) else {
                localClient?.urlProtocol(localSelf, didFailWithError: URLError(.badURL))
                return
            }

            do {
                let (response, data) = try handler(localRequest)

                localClient?.urlProtocol(localSelf, didReceive: response, cacheStoragePolicy: .notAllowed)
                localClient?.urlProtocol(localSelf, didLoad: data)
                localClient?.urlProtocolDidFinishLoading(localSelf)
            } catch {
                localClient?.urlProtocol(localSelf, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {
        // Request cancelled
    }
}

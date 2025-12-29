//
//  MockURLProtocol.swift
//  NetworkKitTests
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

class MockURLProtocol: URLProtocol {
    // MARK: - Types

    typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data)

    // MARK: - Properties

    /// URL Path -> Handler 매핑
    nonisolated(unsafe) static var routes: [String: RequestHandler] = [:]
    private static let lock = NSLock()

    // MARK: - Helper Methods

    static func register(path: String, handler: @escaping RequestHandler) {
        lock.lock()
        defer { lock.unlock() }
        routes[path] = handler
    }

    static func clear() {
        lock.lock()
        defer { lock.unlock() }
        routes.removeAll()
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

        MockURLProtocol.lock.lock()
        let handler = MockURLProtocol.routes[url.path]
        MockURLProtocol.lock.unlock()

        guard let handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            let (response, data) = try handler(request)

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // Request cancelled
    }
}

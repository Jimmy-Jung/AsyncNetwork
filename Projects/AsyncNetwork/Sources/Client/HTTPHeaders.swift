//
//  HTTPHeaders.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

/// HTTP 헤더 관리 및 생성을 담당하는 구조체 (메서드 체이닝 방식)
public struct HTTPHeaders: Sendable {
    // MARK: - Properties

    private var headers: [String: String] = [:]

    // MARK: - Static Header Keys

    public enum HeaderKey: String, CaseIterable, Sendable {
        case contentType = "Content-Type"
        case accept = "Accept"
        case authorization = "Authorization"
        case userAgent = "User-Agent"
        case acceptLanguage = "Accept-Language"
        case appVersion = "X-App-Version"
        case deviceModel = "X-Device-Model"
        case osVersion = "X-OS-Version"
        case bundleId = "X-Bundle-Id"
        case requestId = "X-Request-Id"
        case timestamp = "X-Timestamp"
        case sessionId = "X-Session-Id"
        case clientVersion = "X-Client-Version"
        case platform = "X-Platform"
    }

    // MARK: - Content Types

    public enum ContentType: String {
        case json = "application/json"
        case formURLEncoded = "application/x-www-form-urlencoded"
        case formData = "multipart/form-data"
        case textPlain = "text/plain"

        /// UTF-8 인코딩이 포함된 Content-Type
        public var withUTF8: String {
            switch self {
            case .json:
                return "application/json; charset=UTF-8"
            case .formURLEncoded:
                return "application/x-www-form-urlencoded; charset=UTF-8"
            case .textPlain:
                return "text/plain; charset=UTF-8"
            case .formData:
                return rawValue // multipart는 boundary가 별도로 설정됨
            }
        }
    }

    public init() {}

    public init(headers: [String: String]) {
        self.headers = headers
    }

    @discardableResult
    public func contentType(_ contentType: ContentType) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.contentType.rawValue] = contentType.withUTF8
        return newHeaders
    }

    @discardableResult
    public func accept(_ contentType: ContentType) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.accept.rawValue] = contentType.rawValue
        return newHeaders
    }

    @discardableResult
    public func authorization(_ token: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.authorization.rawValue] = token
        return newHeaders
    }

    @discardableResult
    public func userAgent(_ userAgent: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.userAgent.rawValue] = userAgent
        return newHeaders
    }

    @discardableResult
    public func acceptLanguage(_ language: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.acceptLanguage.rawValue] = language
        return newHeaders
    }

    @discardableResult
    public func appVersion(_ version: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.appVersion.rawValue] = version
        return newHeaders
    }

    @discardableResult
    public func deviceModel(_ model: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.deviceModel.rawValue] = model
        return newHeaders
    }

    @discardableResult
    public func osVersion(_ version: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.osVersion.rawValue] = version
        return newHeaders
    }

    @discardableResult
    public func bundleId(_ bundleId: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.bundleId.rawValue] = bundleId
        return newHeaders
    }

    @discardableResult
    public func requestId(_ requestId: String = UUID().uuidString) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.requestId.rawValue] = requestId
        return newHeaders
    }

    @discardableResult
    public func timestamp(_ timestamp: String = String(Int(Date().timeIntervalSince1970))) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.timestamp.rawValue] = timestamp
        return newHeaders
    }

    @discardableResult
    public func sessionId(_ sessionId: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.sessionId.rawValue] = sessionId
        return newHeaders
    }

    @discardableResult
    public func clientVersion(_ version: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.clientVersion.rawValue] = version
        return newHeaders
    }

    @discardableResult
    public func platform(_ platform: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.platform.rawValue] = platform
        return newHeaders
    }

    @discardableResult
    public func custom(key: String, value: String) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[key] = value
        return newHeaders
    }

    @discardableResult
    public func merge(with additionalHeaders: [String: String]) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers.merge(additionalHeaders) { _, new in new }
        return newHeaders
    }

    @discardableResult
    public func defaults() -> HTTPHeaders {
        return contentType(.json)
            .accept(.json)
    }

    @discardableResult
    public func form() -> HTTPHeaders {
        return contentType(.formURLEncoded)
            .accept(.json)
    }

    @discardableResult
    public func multipart(boundary: String = "Boundary-\(UUID().uuidString)") -> HTTPHeaders {
        var newHeaders = self
        newHeaders.headers[HeaderKey.contentType.rawValue] = "multipart/form-data; boundary=\(boundary)"
        newHeaders.headers[HeaderKey.accept.rawValue] = ContentType.json.rawValue
        return newHeaders
    }

    @discardableResult
    public func authenticated(token: String) -> HTTPHeaders {
        return defaults()
            .authorization(token)
    }

    public func build() -> [String: String] {
        return headers
    }

    public static func defaultHeaders() -> [String: String] {
        return HTTPHeaders().defaults().build()
    }

    public static func authenticatedHeaders(accKey: String? = nil) -> [String: String] {
        var builder = HTTPHeaders().defaults()
        if let accKey {
            builder = builder.authorization(accKey)
        }
        return builder.build()
    }

    public static func formHeaders(accKey: String? = nil) -> [String: String] {
        var builder = HTTPHeaders().form()
        if let accKey {
            builder = builder.authorization(accKey)
        }
        return builder.build()
    }

    public static func multipartHeaders(
        boundary: String = "Boundary-\(UUID().uuidString)",
        accKey: String? = nil
    ) -> [String: String] {
        var builder = HTTPHeaders().multipart(boundary: boundary)
        if let accKey {
            builder = builder.authorization(accKey)
        }
        return builder.build()
    }
}

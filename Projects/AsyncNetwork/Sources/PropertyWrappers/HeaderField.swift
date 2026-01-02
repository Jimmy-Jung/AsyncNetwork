//
//  HeaderField.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/01.
//

import Foundation

/// HTTPHeaders.HeaderKey를 활용한 타입 안전한 헤더 관리
///
/// **사용 예시:**
/// ```swift
/// @APIRequest(...)
/// struct GetCurrentUserRequest {
///     @HeaderField(key: .authorization) var authorization: String?
///     @HeaderField(key: .requestId) var requestId: String? = UUID().uuidString
///     @HeaderField(key: .userAgent) var userAgent: String?
/// }
///
/// let request = GetCurrentUserRequest(
///     authorization: "Bearer token123",
///     userAgent: "MyApp/1.0.0"
/// )
/// ```
@propertyWrapper
public struct HeaderField<Value: Sendable>: RequestParameter {
    public var wrappedValue: Value?
    private let key: HTTPHeaders.HeaderKey

    public init(wrappedValue: Value? = nil, key: HTTPHeaders.HeaderKey) {
        self.key = key
        self.wrappedValue = wrappedValue
    }

    public func apply(to request: inout URLRequest, key _: String) throws {
        guard let value = wrappedValue else { return }
        request.setValue("\(value)", forHTTPHeaderField: key.rawValue)
    }
}

/// 커스텀 헤더용 (HTTPHeaders.HeaderKey에 없는 경우)
///
/// **사용 예시:**
/// ```swift
/// @APIRequest(...)
/// struct DownloadFileRequest {
///     @CustomHeader("X-Download-Format") var format: String? = "zip"
///     @CustomHeader("X-Quality") var quality: String?
/// }
/// ```
@propertyWrapper
public struct CustomHeader<Value: Sendable>: RequestParameter {
    public var wrappedValue: Value?
    private let headerName: String

    public init(wrappedValue: Value? = nil, _ headerName: String) {
        self.headerName = headerName
        self.wrappedValue = wrappedValue
    }

    public func apply(to request: inout URLRequest, key _: String) throws {
        guard let value = wrappedValue else { return }
        request.setValue("\(value)", forHTTPHeaderField: headerName)
    }
}

//
//  EndpointMetadata.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/11.
//

import Foundation

/// API 엔드포인트 메타데이터
///
/// `@APIRequest` 매크로가 각 Request 타입에 `static var metadata` 프로퍼티를 생성합니다.
public struct EndpointMetadata: Sendable, Equatable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let method: String
    public let path: String
    public let baseURLString: String
    public let headers: [String: String]
    public let tags: [String]
    public let parameters: [String]
    public let responseTypeName: String

    public init(
        id: String,
        title: String,
        description: String,
        method: String,
        path: String,
        baseURLString: String,
        headers: [String: String] = [:],
        tags: [String] = [],
        parameters: [String] = [],
        responseTypeName: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.method = method
        self.path = path
        self.baseURLString = baseURLString
        self.headers = headers
        self.tags = tags
        self.parameters = parameters
        self.responseTypeName = responseTypeName
    }
}

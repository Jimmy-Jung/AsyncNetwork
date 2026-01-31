//
//  DocumentableRequest.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/02/01.
//

import AsyncNetwork
import Foundation

/// API 문서화 메타데이터
///
/// API Playground UI, 문서 생성 등에 사용됩니다.
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
        headers: [String: String],
        tags: [String],
        parameters: [String],
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

/// 문서화 가능한 API 요청 프로토콜
///
/// API Playground UI 또는 문서 생성이 필요한 경우 이 프로토콜을 채택합니다.
/// Sample앱 전용으로, AsyncNetwork 코어와는 독립적입니다.
public protocol DocumentableRequest: APIRequest {
    /// 엔드포인트 메타데이터
    ///
    /// API Playground UI에서 API 목록 표시, 문서 생성 등에 사용됩니다.
    static var metadata: EndpointMetadata { get }
}

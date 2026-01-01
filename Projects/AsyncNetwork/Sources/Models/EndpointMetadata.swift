//
//  EndpointMetadata.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/01.
//

import Foundation

/// API 엔드포인트의 문서화 메타데이터
public struct EndpointMetadata: Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let method: String
    public let path: String
    public let baseURLString: String
    public let headers: [String: String]?
    public let tags: [String]
    public let parameters: [ParameterInfo]
    public let requestBodyExample: String?
    public let responseStructure: String?
    public let responseExample: String?
    public let responseTypeName: String
    
    public init(
        id: String,
        title: String,
        description: String,
        method: String,
        path: String,
        baseURLString: String,
        headers: [String: String]? = nil,
        tags: [String] = [],
        parameters: [ParameterInfo] = [],
        requestBodyExample: String? = nil,
        responseStructure: String? = nil,
        responseExample: String? = nil,
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
        self.requestBodyExample = requestBodyExample
        self.responseStructure = responseStructure
        self.responseExample = responseExample
        self.responseTypeName = responseTypeName
    }
}

/// 파라미터 정보
public struct ParameterInfo: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let type: String
    public let location: ParameterLocation
    public let isRequired: Bool
    public let description: String?
    public let defaultValue: String?
    public let exampleValue: String?
    
    public init(
        id: String,
        name: String,
        type: String,
        location: ParameterLocation,
        isRequired: Bool = false,
        description: String? = nil,
        defaultValue: String? = nil,
        exampleValue: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.location = location
        self.isRequired = isRequired
        self.description = description
        self.defaultValue = defaultValue
        self.exampleValue = exampleValue
    }
}

/// 파라미터 위치
public enum ParameterLocation: String, Sendable, Hashable {
    case query
    case path
    case header
    case body
}


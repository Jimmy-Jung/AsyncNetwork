//
//  EndpointCategory.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/01.
//

import Foundation
import AsyncNetworkCore

/// 카테고리별 엔드포인트 그룹
public struct EndpointCategory: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let description: String?
    public let endpoints: [EndpointMetadata]

    public init(
        name: String,
        description: String? = nil,
        endpoints: [EndpointMetadata]
    ) {
        self.id = name
        self.name = name
        self.description = description
        self.endpoints = endpoints
    }
}

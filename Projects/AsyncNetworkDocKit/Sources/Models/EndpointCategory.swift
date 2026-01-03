//
//  EndpointCategory.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/03.
//

import AsyncNetworkCore
import Foundation

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
        id = name
        self.name = name
        self.description = description
        self.endpoints = endpoints
    }
}

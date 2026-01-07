//
//  ErrorModels.swift
//  OpenAPIExample
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetwork
import AsyncNetworkMacros
import Foundation

// MARK: - Error Models

@Response(
    fixtureJSON: """
    {
      "error": "Resource not found",
      "code": "NOT_FOUND",
      "timestamp": "2026-01-06T10:30:00Z"
    }
    """
)
struct NotFoundError: Codable, Sendable {
    let error: String
    let code: String
    let timestamp: String
}

@Response(
    fixtureJSON: """
    {
      "error": "Internal server error",
      "code": "INTERNAL_ERROR",
      "timestamp": "2026-01-06T10:30:00Z",
      "requestId": "req-12345"
    }
    """
)
struct ServerError: Codable, Sendable {
    let error: String
    let code: String
    let timestamp: String
    let requestId: String
}

@Response(
    fixtureJSON: """
    {
      "error": "Invalid request",
      "code": "BAD_REQUEST",
      "details": ["Field 'email' is required", "Field 'password' must be at least 8 characters"]
    }
    """
)
struct BadRequestError: Codable, Sendable {
    let error: String
    let code: String
    let details: [String]
}

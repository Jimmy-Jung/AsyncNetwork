//
//  ErrorModels.swift
//  OpenAPIExample
//
//  Created by jimmy on 2026/01/06.
//  Updated: 2026/01/14 - Improved error models
//

import AsyncNetwork
import Foundation

// MARK: - Error Models

@ResponseTestablestruct NotFoundError: Codable, Sendable, Error {
    let error: String
    let code: String
    let timestamp: String
}

@ResponseTestablestruct ServerError: Codable, Sendable, Error {
    let error: String
    let code: String
    let timestamp: String
    let requestId: String
}

@ResponseTestablestruct BadRequestError: Codable, Sendable, Error {
    let error: String
    let code: String
    let details: [String]
}

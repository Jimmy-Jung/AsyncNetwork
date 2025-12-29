//
//  APIResponse.swift
//  AsyncNetworkExample
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

struct APIResponse: Identifiable, Hashable, Sendable {
    let id: String
    let statusCode: Int
    let description: String
    let schema: String
    let example: String

    init(
        statusCode: Int,
        description: String,
        schema: String,
        example: String
    ) {
        id = "\(statusCode)"
        self.statusCode = statusCode
        self.description = description
        self.schema = schema
        self.example = example
    }
}

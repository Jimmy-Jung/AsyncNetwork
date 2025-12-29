//
//  RequestBody.swift
//  NetworkKitExample
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

struct RequestBody: Hashable, Sendable {
    let required: Bool
    let contentType: String
    let schema: String
    let example: String

    init(
        required: Bool = true,
        contentType: String = "application/json",
        schema: String,
        example: String
    ) {
        self.required = required
        self.contentType = contentType
        self.schema = schema
        self.example = example
    }
}

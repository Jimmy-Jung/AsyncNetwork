//
//  APIParameter.swift
//  NetworkKitExample
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

struct APIParameter: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let location: ParameterLocation
    let type: String
    let required: Bool
    let description: String
    let example: String?
    let defaultValue: String?

    init(
        name: String,
        location: ParameterLocation,
        type: String,
        required: Bool = false,
        description: String,
        example: String? = nil,
        defaultValue: String? = nil
    ) {
        id = name
        self.name = name
        self.location = location
        self.type = type
        self.required = required
        self.description = description
        self.example = example
        self.defaultValue = defaultValue
    }
}

enum ParameterLocation: String, Hashable, Sendable {
    case path
    case query
    case header
    case body
}

//
//  APIEndpoint.swift
//  NetworkKitExample
//
//  Created by jimmy on 2025/12/29.
//

import Foundation
import NetworkKit

struct APIEndpoint: Identifiable, Hashable, Sendable {
    let id: String
    let category: String
    let method: HTTPMethod
    let path: String
    let summary: String
    let description: String
    let parameters: [APIParameter]
    let requestBody: RequestBody?
    let responses: [APIResponse]
    let baseURL: String

    init(
        id: String,
        category: String,
        method: HTTPMethod,
        path: String,
        summary: String,
        description: String,
        parameters: [APIParameter] = [],
        requestBody: RequestBody? = nil,
        responses: [APIResponse] = [],
        baseURL: String = "https://jsonplaceholder.typicode.com"
    ) {
        self.id = id
        self.category = category
        self.method = method
        self.path = path
        self.summary = summary
        self.description = description
        self.parameters = parameters
        self.requestBody = requestBody
        self.responses = responses
        self.baseURL = baseURL
    }
}

extension APIEndpoint {
    var methodColor: String {
        switch method {
        case .get: return "blue"
        case .post: return "green"
        case .put: return "orange"
        case .patch: return "orange"
        case .delete: return "red"
        case .head: return "purple"
        case .options: return "gray"
        }
    }
}

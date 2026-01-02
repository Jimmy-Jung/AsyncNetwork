//
//  DynamicAPIRequest.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/01.
//

import Foundation
import AsyncNetworkCore

/// 동적으로 생성되는 APIRequest (API Tester용)
struct DynamicAPIRequest: APIRequest {
    typealias Response = Data

    let baseURLString: String
    let path: String
    let method: HTTPMethod
    let task: HTTPTask
    let headers: [String: String]?
    let timeout: TimeInterval

    init(
        baseURL: String,
        path: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        body: Data? = nil
    ) {
        self.baseURLString = baseURL
        self.path = path
        self.method = method
        self.headers = headers
        self.timeout = 30

        // HTTPTask 설정
        if let body = body {
            self.task = .requestData(body)
        } else if let queryParams = queryParameters, !queryParams.isEmpty {
            self.task = .requestQueryParameters(parameters: queryParams)
        } else {
            self.task = .requestPlain
        }
    }

    func parseResponse(data: Data, response: HTTPURLResponse) throws -> Data {
        return data
    }
}

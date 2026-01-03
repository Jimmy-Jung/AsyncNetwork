//
//  DynamicAPIRequest.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/03.
//

import AsyncNetworkCore
import Foundation

struct DynamicAPIRequest: APIRequest {
    typealias Response = Data

    let baseURLString: String
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let timeout: TimeInterval
    private let bodyData: Data?

    init(
        baseURL: String,
        path: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        body: Data? = nil
    ) {
        baseURLString = baseURL
        self.path = path
        self.method = method
        self.headers = headers
        timeout = 30
        bodyData = body
        dynamicQueryParameters = queryParameters
    }

    private let dynamicQueryParameters: [String: String]?

    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: baseURLString + path)

        if let queryParams = dynamicQueryParameters, !queryParams.isEmpty {
            components?.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method.rawValue

        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        if let body = bodyData {
            request.httpBody = body
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }

        return request
    }

    func parseResponse(data: Data, response _: HTTPURLResponse) throws -> Data {
        return data
    }
}

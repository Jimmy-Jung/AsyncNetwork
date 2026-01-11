//
//  DynamicAPIRequest.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/11.
//

import AsyncNetwork
import Foundation

/// API Playground에서 동적으로 생성되는 API 요청
struct DynamicAPIRequest: APIRequest {
    typealias Response = Data

    let baseURLString: String
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let timeout: TimeInterval

    @RawRequestBody private var body: Data?

    init(
        baseURL: String,
        path: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        queryParameters _: [String: String]? = nil,
        body: Data? = nil
    ) {
        baseURLString = baseURL
        self.path = path
        self.method = method
        self.headers = headers
        timeout = 30
        _body = RawRequestBody(wrappedValue: body)
    }
}

/// Raw Data를 직접 Request Body로 설정하는 Property Wrapper
@propertyWrapper
struct RawRequestBody: RequestParameter {
    var wrappedValue: Data?

    init(wrappedValue: Data? = nil) {
        self.wrappedValue = wrappedValue
    }

    func apply(to request: inout URLRequest, key _: String) throws {
        guard let data = wrappedValue else { return }

        request.httpBody = data

        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    }
}

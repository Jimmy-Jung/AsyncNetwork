//
//  DynamicAPIRequest.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/01.
//

import AsyncNetworkCore
import Foundation

/// 동적으로 생성되는 APIRequest (API Tester용)
struct DynamicAPIRequest: APIRequest {
    typealias Response = Data

    let baseURLString: String
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let timeout: TimeInterval

    // 동적 body data (PropertyWrapper 대신 수동 처리)
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

        // queryParameters는 동적으로 처리하기 위해 별도 저장
        dynamicQueryParameters = queryParameters
    }

    // 동적 query parameters
    private let dynamicQueryParameters: [String: String]?

    // asURLRequest 오버라이드 (동적 파라미터 처리)
    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: baseURLString + path)

        // 동적 쿼리 파라미터 추가
        if let queryParams = dynamicQueryParameters, !queryParams.isEmpty {
            components?.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components?.url else {
            // URL 생성 실패 시 URLError 사용
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method.rawValue

        // 헤더 추가
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        // Body 데이터 추가
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

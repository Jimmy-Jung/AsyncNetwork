//
//  HTTPTask.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

/// HTTP 요청 태스크 정의
public enum HTTPTask: Sendable {
    /// 바디 없는 요청
    case requestPlain

    /// Data 바디 요청
    case requestData(Data)

    /// JSON Encodable 바디 요청
    case requestJSONEncodable(any Encodable & Sendable)

    /// Parameters 바디 요청 (application/x-www-form-urlencoded)
    case requestParameters(parameters: [String: String])

    /// Query Parameters 요청
    case requestQueryParameters(parameters: [String: String])
}

// MARK: - URLRequest Conversion

public extension HTTPTask {
    /// HTTPTask를 URLRequest에 적용
    func apply(to request: inout URLRequest) throws {
        switch self {
        case .requestPlain:
            break

        case let .requestData(data):
            request.httpBody = data

        case let .requestJSONEncodable(encodable):
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(encodable)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        case let .requestParameters(parameters):
            let bodyString = parameters
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            request.httpBody = bodyString.data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        case let .requestQueryParameters(parameters):
            guard let url = request.url else { return }
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            request.url = components?.url
        }
    }
}

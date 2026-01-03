//
//  APIRequest.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

/// API 요청을 나타내는 프로토콜
public protocol APIRequest: Sendable {
    associatedtype Response: Decodable = EmptyResponse

    var baseURLString: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var timeout: TimeInterval { get }
}

public extension APIRequest {
    var timeout: TimeInterval { 30.0 }
    var headers: [String: String]? { nil }

    func getBaseURL() throws -> URL {
        guard let url = URL(string: baseURLString) else {
            throw NetworkError.invalidURL(baseURLString)
        }
        return url
    }
}

public extension APIRequest {
    func asURLRequest() throws -> URLRequest {
        let baseURL = try getBaseURL()
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method.rawValue

        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let label = child.label else { continue }

            let propertyName = label.hasPrefix("_") ? String(label.dropFirst()) : label

            if let param = child.value as? RequestParameter {
                try param.apply(to: &request, key: propertyName)
            }
        }

        return request
    }
}

public protocol APIResponse: Codable, Sendable {}

public struct EmptyResponse: Codable, Sendable {
    public init() {}
}

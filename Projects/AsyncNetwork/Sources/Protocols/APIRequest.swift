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

    /// 엔드포인트 메타데이터
    /// @APIRequest 매크로가 자동으로 생성합니다.
    static var metadata: EndpointMetadata { get }
}

public extension APIRequest {
    var timeout: TimeInterval { 30.0 }
    var headers: [String: String]? { nil }

    /// 기본 메타데이터 구현
    /// @APIRequest 매크로가 적용된 타입은 자동으로 이 구현을 오버라이드합니다.
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "\(Self.self)",
            title: "\(Self.self)",
            description: "",
            method: "GET",
            path: "",
            baseURLString: "",
            headers: [:],
            tags: [],
            parameters: [],
            responseTypeName: "EmptyResponse"
        )
    }

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

        // path 정규화: "/"로 시작하면 제거하여 상대 경로로 처리
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path

        // path를 여러 컴포넌트로 분리하여 각각 추가
        let pathComponents = normalizedPath.split(separator: "/").map(String.init)
        var url = baseURL
        for component in pathComponents {
            url = url.appendingPathComponent(component)
        }

        // 최종 URL 검증
        guard url.scheme != nil, url.host != nil else {
            throw NetworkError.invalidURL("\(baseURL.absoluteString)/\(normalizedPath)")
        }

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

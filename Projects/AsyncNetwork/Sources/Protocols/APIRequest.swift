//
//  APIRequest.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/03.
//

import Foundation

/// API 요청을 나타내는 프로토콜
///
/// 이 프로토콜은 네트워크 요청 실행에 필요한 최소한의 프로퍼티만 정의합니다.
/// 문서화 및 메타데이터가 필요한 경우 `DocumentableAPIRequest` 프로토콜을 사용하세요.
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

/// 문서화 가능한 API 요청 프로토콜
///
/// API Playground UI 또는 OpenAPI 문서 생성이 필요한 경우 이 프로토콜을 채택합니다.
/// `@APIDocument` 매크로를 사용하면 자동으로 이 프로토콜을 채택하고 `metadata`를 생성합니다.
///
/// ## 사용 예시
///
/// ```swift
/// @APIRequest(response: PostDTO.self, baseURL: "...", path: "/posts", method: .get)
/// @APIDocument(title: "Get all posts", description: "...", tags: ["Posts"])
/// struct GetPostsRequest {
///     @QueryParameter var userId: Int?
/// }
/// // ↑ 자동으로 DocumentableAPIRequest 채택
/// ```
public protocol DocumentableAPIRequest: APIRequest {
    /// 엔드포인트 메타데이터
    ///
    /// API Playground UI에서 API 목록 표시, 문서 생성 등에 사용됩니다.
    /// `@APIDocument` 매크로가 자동으로 생성합니다.
    static var metadata: EndpointMetadata { get }
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

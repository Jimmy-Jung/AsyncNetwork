//
//  APITestRepository.swift
//  AsyncNetworkExample
//
//  Created by jimmy on 2025/12/29.
//

import AsyncNetwork
import Foundation

// MARK: - APITestResult

/// API 테스트 결과
struct APITestResult: Sendable, Equatable {
    let statusCode: Int
    let body: String
    let headers: String
}

// MARK: - APITestRepository

/// API 테스트를 위한 Repository 프로토콜
///
/// ViewModel과 NetworkService 사이의 추상화 레이어를 제공합니다.
/// 테스트 시 Mock 구현체로 대체할 수 있습니다.
protocol APITestRepository: Sendable {
    /// API 요청 실행
    /// - Parameters:
    ///   - endpoint: 테스트할 API 엔드포인트
    ///   - parameters: 요청 파라미터
    ///   - body: 요청 바디 (JSON 문자열)
    /// - Returns: API 테스트 결과
    func executeRequest(
        endpoint: APIEndpoint,
        parameters: [String: String],
        body: String?
    ) async throws -> APITestResult
}

// MARK: - DefaultAPITestRepository

/// APITestRepository의 기본 구현체
///
/// NetworkService를 사용하여 실제 네트워크 요청을 수행합니다.
struct DefaultAPITestRepository: APITestRepository {
    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func executeRequest(
        endpoint: APIEndpoint,
        parameters: [String: String],
        body: String?
    ) async throws -> APITestResult {
        // URL 생성
        var urlString = "\(endpoint.baseURL)\(endpoint.path)"

        // Path parameters 치환
        for (key, value) in parameters where endpoint.parameters.contains(where: { $0.name == key && $0.location == .path }) {
            urlString = urlString.replacingOccurrences(of: "{\(key)}", with: value)
        }

        // Query parameters 추가
        let queryParams = parameters.filter { key, _ in
            endpoint.parameters.contains(
                where: { $0.name == key && $0.location == .query }
            )
        }

        if !queryParams.isEmpty {
            let queryString = queryParams
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            urlString += "?" + queryString
        }

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        // DynamicAPIRequest 생성
        let request = DynamicAPIRequest(
            url: url,
            method: endpoint.method,
            headerDict: [
                "Content-Type": "application/json",
                "Accept": "application/json",
            ],
            body: body?.data(using: .utf8)
        )

        // NetworkService를 통해 요청 실행
        let httpResponse = try await networkService.requestRaw(request)

        // Response 파싱
        let responseBody = formatResponseBody(httpResponse.data)
        let headersString = formatHeaders(httpResponse.response)

        return APITestResult(
            statusCode: httpResponse.statusCode,
            body: responseBody,
            headers: headersString
        )
    }

    // MARK: - Private Helpers

    private func formatResponseBody(_ data: Data) -> String {
        print("📦 [formatResponseBody] Data size: \(data.count) bytes")

        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8)
        {
            print("✅ [formatResponseBody] Successfully formatted, length: \(prettyString.count)")
            return prettyString
        }

        let fallbackString = String(data: data, encoding: .utf8) ?? ""
        print("⚠️ [formatResponseBody] Using fallback, length: \(fallbackString.count)")
        return fallbackString
    }

    private func formatHeaders(_ response: HTTPURLResponse?) -> String {
        guard let response = response else { return "" }
        return response.allHeaderFields
            .compactMap { key, value in
                guard let keyString = key as? String else { return nil }
                return "\(keyString): \(value)"
            }
            .joined(separator: "\n")
    }
}

// MARK: - DynamicAPIRequest

/// 동적 API 요청을 위한 구조체
struct DynamicAPIRequest: APIRequest, Sendable {
    let baseURL: URL
    let path: String
    let method: HTTPMethod
    let task: HTTPTask

    // 완성된 URL을 저장 (쿼리 포함)
    private let fullURL: URL

    // 내부적으로 HTTPHeaders 사용
    private let _headers: HTTPHeaders

    // APIRequest 프로토콜 준수
    var headers: [String: String]? {
        return _headers.build()
    }

    init(
        url: URL,
        method: HTTPMethod,
        headerDict: [String: String] = [:],
        body: Data? = nil
    ) {
        // 완성된 URL 저장
        fullURL = url

        // URLComponents를 사용하여 파싱
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        // baseURL 생성 (scheme + host + port)
        var baseComponents = components
        baseComponents.path = ""
        baseComponents.query = nil
        baseComponents.fragment = nil
        baseURL = baseComponents.url!

        // path만 추출 (query 제외)
        path = components.path

        self.method = method
        _headers = HTTPHeaders(headers: headerDict)

        if let body = body {
            task = .requestData(body)
        } else {
            task = .requestPlain
        }
    }

    // asURLRequest() 오버라이드: 완성된 URL을 그대로 사용
    func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: fullURL, timeoutInterval: timeout)
        request.httpMethod = method.rawValue

        // 헤더 추가
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Task 적용
        try task.apply(to: &request)

        return request
    }
}

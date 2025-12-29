//
//  HTTPResponse.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

/// HTTP 응답
public struct HTTPResponse: Sendable {
    /// HTTP 상태 코드
    public let statusCode: Int

    /// 응답 데이터
    public let data: Data

    /// 원본 URLRequest
    public let request: URLRequest?

    /// 원본 HTTPURLResponse
    public let response: HTTPURLResponse?

    public init(
        statusCode: Int,
        data: Data,
        request: URLRequest? = nil,
        response: HTTPURLResponse? = nil
    ) {
        self.statusCode = statusCode
        self.data = data
        self.request = request
        self.response = response
    }
}

// MARK: - URLSession Response Conversion

extension HTTPResponse {
    /// URLSession의 응답을 HTTPResponse로 변환
    static func from(data: Data, response: URLResponse, request: URLRequest?) throws -> HTTPResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(
                domain: "HTTPResponse",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Response is not HTTPURLResponse"]
            ))
        }

        return HTTPResponse(
            statusCode: httpResponse.statusCode,
            data: data,
            request: request,
            response: httpResponse
        )
    }
}

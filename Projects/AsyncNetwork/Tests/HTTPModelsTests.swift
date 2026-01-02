//
//  HTTPModelsTests.swift
//  NetworkKit
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - HTTPMethodTests

struct HTTPMethodTests {
    @Test("HTTPMethod rawValue 확인", arguments: [
        (HTTPMethod.get, "GET"),
        (HTTPMethod.post, "POST"),
        (HTTPMethod.put, "PUT"),
        (HTTPMethod.delete, "DELETE"),
        (HTTPMethod.patch, "PATCH"),
        (HTTPMethod.head, "HEAD"),
        (HTTPMethod.options, "OPTIONS")
    ])
    func httpMethodRawValues(method: HTTPMethod, expectedRawValue: String) {
        #expect(method.rawValue == expectedRawValue)
    }
}

// MARK: - HTTPResponseTests

struct HTTPResponseTests {
    @Test("HTTPResponse 초기화 - 기본값")
    func initializationWithDefaults() {
        // Given
        let statusCode = 200
        let data = Data("test".utf8)

        // When
        let response = HTTPResponse(statusCode: statusCode, data: data)

        // Then
        #expect(response.statusCode == statusCode)
        #expect(response.data == data)
        #expect(response.request == nil)
        #expect(response.response == nil)
    }

    @Test("HTTPResponse 초기화 - 전체 파라미터")
    func initializationWithAllParameters() throws {
        // Given
        let statusCode = 201
        let data = Data("response data".utf8)
        let url = try #require(URL(string: "https://api.example.com/test"))
        let request = URLRequest(url: url)
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )

        // When
        let response = HTTPResponse(
            statusCode: statusCode,
            data: data,
            request: request,
            response: httpResponse
        )

        // Then
        #expect(response.statusCode == statusCode)
        #expect(response.data == data)
        #expect(response.request == request)
        #expect(response.response == httpResponse)
    }

    @Test("HTTPResponse.from - 유효한 HTTPURLResponse")
    func fromValidHTTPURLResponse() throws {
        // Given
        let url = try #require(URL(string: "https://api.example.com/test"))
        let request = URLRequest(url: url)
        let data = Data("test data".utf8)
        let urlResponse = try #require(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))

        // When
        let response = try HTTPResponse.from(data: data, response: urlResponse, request: request)

        // Then
        #expect(response.statusCode == 200)
        #expect(response.data == data)
        #expect(response.request == request)
        #expect(response.response == urlResponse)
    }

    @Test("HTTPResponse.from - 다양한 상태 코드", arguments: [200, 201, 204, 301, 400, 404, 500, 503])
    func fromVariousStatusCodes(statusCode: Int) throws {
        // Given
        let url = try #require(URL(string: "https://api.example.com/test"))
        let request = URLRequest(url: url)
        let data = Data()
        let urlResponse = try #require(HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        ))

        // When
        let response = try HTTPResponse.from(data: data, response: urlResponse, request: request)

        // Then
        #expect(response.statusCode == statusCode)
    }

    @Test("HTTPResponse.from - 비 HTTPURLResponse 에러 발생")
    func fromNonHTTPURLResponseThrowsError() throws {
        // Given
        let url = try #require(URL(string: "https://api.example.com/test"))
        let request = URLRequest(url: url)
        let data = Data()
        let urlResponse = URLResponse(
            url: url,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )

        // When & Then
        #expect(throws: NetworkError.self) {
            try HTTPResponse.from(data: data, response: urlResponse, request: request)
        }
    }
}

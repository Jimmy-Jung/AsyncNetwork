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
        (HTTPMethod.options, "OPTIONS"),
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

// MARK: - HTTPTaskTests

struct HTTPTaskTests {
    @Test("HTTPTask.requestPlain - 요청 본문 없음")
    func requestPlainNoBody() throws {
        // Given
        let url = try #require(URL(string: "https://api.example.com/test"))
        var request = URLRequest(url: url)
        let task = HTTPTask.requestPlain

        // When
        try task.apply(to: &request)

        // Then
        #expect(request.httpBody == nil)
    }

    @Test("HTTPTask.requestData - 데이터 본문 설정")
    func requestDataSetsBody() throws {
        // Given
        let url = try #require(URL(string: "https://api.example.com/test"))
        var request = URLRequest(url: url)
        let data = Data("test data".utf8)
        let task = HTTPTask.requestData(data)

        // When
        try task.apply(to: &request)

        // Then
        #expect(request.httpBody == data)
    }

    @Test("HTTPTask.requestJSONEncodable - JSON 인코딩 및 Content-Type 설정")
    func requestJSONEncodableSetsBodyAndContentType() throws {
        // Given
        struct TestModel: Codable, Sendable {
            let name: String
            let age: Int
        }

        let url = try #require(URL(string: "https://api.example.com/test"))
        var request = URLRequest(url: url)
        let model = TestModel(name: "John", age: 30)
        let task = HTTPTask.requestJSONEncodable(model)

        // When
        try task.apply(to: &request)

        // Then
        #expect(request.httpBody != nil)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        // JSON 내용 검증
        let decoded = try JSONDecoder().decode(TestModel.self, from: request.httpBody!)
        #expect(decoded.name == "John")
        #expect(decoded.age == 30)
    }

    @Test("HTTPTask.requestParameters - Form URL Encoded 본문 설정")
    func requestParametersSetsBodyAndContentType() throws {
        // Given
        let url = try #require(URL(string: "https://api.example.com/test"))
        var request = URLRequest(url: url)
        let parameters = ["key1": "value1", "key2": "value2"]
        let task = HTTPTask.requestParameters(parameters: parameters)

        // When
        try task.apply(to: &request)

        // Then
        #expect(request.httpBody != nil)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")

        let bodyString = String(data: request.httpBody!, encoding: .utf8)!
        #expect(bodyString.contains("key1=value1"))
        #expect(bodyString.contains("key2=value2"))
    }

    @Test("HTTPTask.requestQueryParameters - 쿼리 파라미터 설정")
    func requestQueryParametersSetsQueryItems() throws {
        // Given
        let url = try #require(URL(string: "https://api.example.com/test"))
        var request = URLRequest(url: url)
        let parameters = ["page": "1", "limit": "10"]
        let task = HTTPTask.requestQueryParameters(parameters: parameters)

        // When
        try task.apply(to: &request)

        // Then
        let urlString = request.url?.absoluteString ?? ""
        #expect(urlString.contains("page=1"))
        #expect(urlString.contains("limit=10"))
        #expect(request.httpBody == nil)
    }

    @Test("HTTPTask.requestQueryParameters - 빈 파라미터")
    func requestQueryParametersEmptyParameters() throws {
        // Given
        let url = try #require(URL(string: "https://api.example.com/test"))
        var request = URLRequest(url: url)
        let parameters: [String: String] = [:]
        let task = HTTPTask.requestQueryParameters(parameters: parameters)

        // When
        try task.apply(to: &request)

        // Then
        // 빈 파라미터의 경우 URL에 ? 가 추가될 수 있음
        let urlString = request.url?.absoluteString ?? ""
        #expect(urlString.hasPrefix("https://api.example.com/test"))
    }

    @Test("HTTPTask.requestQueryParameters - nil URL 처리")
    func requestQueryParametersNilURL() throws {
        // Given
        var request = URLRequest(url: URL(string: "about:blank")!)
        request.url = nil
        let parameters = ["key": "value"]
        let task = HTTPTask.requestQueryParameters(parameters: parameters)

        // When
        try task.apply(to: &request)

        // Then - nil URL이면 아무 작업도 하지 않음
        #expect(request.url == nil)
    }
}

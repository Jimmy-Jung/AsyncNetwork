//
//  TestableSemerTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/06.
//

import AsyncNetworkCore
import AsyncNetworkMacros
import Foundation
import Testing

// Test DTO
@TestableDTO(
    fixtureJSON: """
    {
      "id": 1,
      "title": "Test Post",
      "body": "This is a test post"
    }
    """
)
struct Post: Codable {
    let id: Int
    let title: String
    let body: String
}

// Test API Request with @TestableSchemer
@APIRequest(
    response: Post.self,
    title: "Get Post",
    baseURL: "https://api.example.com",
    path: "/posts/:id",
    method: .get
)
@TestableSchemer(
    scenarios: [.success, .notFound, .serverError],
    includeRetryTests: true,
    errorExamples: [
        "404": """
        {
          "error": "Post not found",
          "code": "POST_NOT_FOUND"
        }
        """,
        "500": """
        {
          "error": "Internal server error",
          "code": "INTERNAL_ERROR"
        }
        """,
    ]
)
struct GetPostRequest {
    @PathParameter var id: Int = 1
}

@Suite("@TestableSchemer Macro Tests")
struct TestableSemerTests {
    @Test("MockScenario enum 생성 확인")
    func mockScenarioEnum() {
        // MockScenario enum이 생성되었는지 확인
        let _: GetPostRequest.MockScenario = .success
        let _: GetPostRequest.MockScenario = .notFound
        let _: GetPostRequest.MockScenario = .serverError
        let _: GetPostRequest.MockScenario = .networkError
        let _: GetPostRequest.MockScenario = .timeout

        // enum이 정상적으로 생성되었음
        #expect(true)
    }

    @Test("mockResponse - Success 시나리오")
    func mockResponseSuccess() {
        let (data, response, error) = GetPostRequest.mockResponse(for: .success)

        #expect(data != nil)
        #expect(response != nil)
        #expect(error == nil)

        if let httpResponse = response as? HTTPURLResponse {
            #expect(httpResponse.statusCode == 200)
        }

        // 데이터 디코딩 확인
        if let data = data {
            let post = try? JSONDecoder().decode(Post.self, from: data)
            #expect(post != nil)
            #expect(post?.id == 1)
        }
    }

    @Test("mockResponse - NotFound 시나리오")
    func mockResponseNotFound() {
        let (data, response, error) = GetPostRequest.mockResponse(for: .notFound)

        #expect(data != nil)
        #expect(response != nil)
        #expect(error == nil)

        if let httpResponse = response as? HTTPURLResponse {
            #expect(httpResponse.statusCode == 404)
        }

        // 에러 메시지 확인
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            #expect(json["error"] as? String == "Post not found")
            #expect(json["code"] as? String == "POST_NOT_FOUND")
        }
    }

    @Test("mockResponse - ServerError 시나리오")
    func mockResponseServerError() {
        let (_, response, error) = GetPostRequest.mockResponse(for: .serverError)

        #expect(response != nil)
        #expect(error == nil)

        if let httpResponse = response as? HTTPURLResponse {
            #expect(httpResponse.statusCode == 500)
        }
    }

    @Test("mockResponse - NetworkError 시나리오")
    func mockResponseNetworkError() {
        let (data, response, error) = GetPostRequest.mockResponse(for: .networkError)

        #expect(data == nil)
        #expect(response == nil)
        #expect(error != nil)

        if let urlError = error as? URLError {
            #expect(urlError.code == .notConnectedToInternet)
        }
    }

    @Test("mockResponse - Timeout 시나리오")
    func mockResponseTimeout() {
        let (data, response, error) = GetPostRequest.mockResponse(for: .timeout)

        #expect(data == nil)
        #expect(response == nil)
        #expect(error != nil)

        if let urlError = error as? URLError {
            #expect(urlError.code == .timedOut)
        }
    }
}

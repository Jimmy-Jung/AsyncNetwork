//
//  PostRequestsTestCasesTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by jimmy on 2026/01/29.
//  Split from PostRequestsTests.swift for required body test cases
//

import AsyncNetwork
@testable import AsyncNetworkSampleApp
import Foundation
import Testing

@Suite("Post API Requests - Required Body Test Cases")
struct PostRequestsTestCasesTests {
    // MARK: - Required Body Tests

    @Test("CreatePostWithRequiredBodyRequest - 필수 body가 항상 인코딩되는지 확인")
    func createPostWithRequiredBody() throws {
        // Given
        let body = PostBodyDTO(
            title: "Required Test Post",
            body: "This tests required (non-optional) body",
            userId: 1
        )
        let request = CreatePostWithRequiredBodyRequest(body: body)

        // When
        var urlRequest = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
        try request.$body.apply(to: &urlRequest, key: "body")

        // Then
        let httpBody = try #require(urlRequest.httpBody, "필수 body는 nil일 수 없음")
        let decoded = try JSONDecoder().decode(PostBodyDTO.self, from: httpBody)
        #expect(decoded.title == body.title)
        #expect(decoded.body == body.body)
        #expect(decoded.userId == body.userId)
    }

    @Test("UpdatePostWithRequiredBodyRequest - PathParameter와 필수 body 함께 사용")
    func updatePostWithRequiredBodyAndPathParameter() throws {
        // Given
        let postId = 42
        let body = PostBodyDTO(
            title: "Updated Post",
            body: "Updated content",
            userId: 2
        )
        let request = UpdatePostWithRequiredBodyRequest(id: postId, body: body)

        // When
        var urlRequest = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/posts/{id}")!)
        try request.$id.apply(to: &urlRequest, key: "id")
        try request.$body.apply(to: &urlRequest, key: "body")

        // Then
        // PathParameter 확인
        let finalURL = try #require(urlRequest.url)
        #expect(finalURL.absoluteString.contains("posts/42"))

        // 필수 body 확인
        let httpBody = try #require(urlRequest.httpBody, "필수 body는 nil일 수 없음")
        let decoded = try JSONDecoder().decode(PostBodyDTO.self, from: httpBody)
        #expect(decoded.title == body.title)
        #expect(decoded.body == body.body)
        #expect(decoded.userId == body.userId)
    }

    @Test("CreatePostWithRequiredBodyRequest - Success 시나리오")
    func createPostWithRequiredBodySuccessScenario() throws {
        // Given
        let (data, response, error) = CreatePostWithRequiredBodyRequest.mockResponse(for: .success)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)

        let responseData = try #require(data)
        let post = try JSONDecoder().decode(PostDTO.self, from: responseData)
        #expect(post.id > 0)
    }

    @Test("UpdatePostWithRequiredBodyRequest - Success 시나리오")
    func updatePostWithRequiredBodySuccessScenario() throws {
        // Given
        let (data, response, error) = UpdatePostWithRequiredBodyRequest.mockResponse(for: .success)

        // Then
        #expect(error == nil)

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)

        let responseData = try #require(data)
        let post = try JSONDecoder().decode(PostDTO.self, from: responseData)
        #expect(post.id > 0)
    }

    @Test("필수 body vs 옵셔널 body 비교")
    func requiredVsOptionalBody() throws {
        // Given - 옵셔널 body (기존)
        let optionalRequest = CreatePostRequest(body: nil)
        var optionalURLRequest = URLRequest(url: URL(string: "https://test.com")!)

        // When
        try optionalRequest.$body.apply(to: &optionalURLRequest, key: "body")

        // Then - 옵셔널이고 nil이면 httpBody가 설정되지 않음
        #expect(optionalURLRequest.httpBody == nil, "옵셔널 body가 nil이면 httpBody도 nil")

        // Given - 필수 body (새로운)
        let body = PostBodyDTO(title: "Test", body: "Content", userId: 1)
        let requiredRequest = CreatePostWithRequiredBodyRequest(body: body)
        var requiredURLRequest = URLRequest(url: URL(string: "https://test.com")!)

        // When
        try requiredRequest.$body.apply(to: &requiredURLRequest, key: "body")

        // Then - 필수 body는 항상 httpBody가 설정됨
        #expect(requiredURLRequest.httpBody != nil, "필수 body는 항상 httpBody가 설정됨")
    }
}

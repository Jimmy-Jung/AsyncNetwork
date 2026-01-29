//
//  CombinedPropertyWrappersTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

/// 여러 Property Wrapper를 조합한 복합 시나리오 테스트
@Suite("Combined PropertyWrappers Tests")
struct CombinedPropertyWrappersTests {
    @Test("모든 PropertyWrapper 동시 적용")
    func allPropertyWrappers() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.search = "test"
        request.limit = 10
        request.authorization = "Bearer token"
        request.contentType = "application/json"
        request.customHeader = "CustomValue"
        request.body = TestBody(name: "Test", value: 42)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        // Query Parameters
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems

        let hasSearch = queryItems?.contains(where: { $0.name == "search" && $0.value == "test" }) ?? false
        let hasLimit = queryItems?.contains(where: { $0.name == "limit" && $0.value == "10" }) ?? false
        #expect(hasSearch == true)
        #expect(hasLimit == true)

        // Headers
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(urlRequest.value(forHTTPHeaderField: "X-Custom-Header") == "CustomValue")

        // Body
        let bodyData = try #require(urlRequest.httpBody)
        let decodedBody = try JSONDecoder().decode(TestBody.self, from: bodyData)
        #expect(decodedBody.name == "Test")
        #expect(decodedBody.value == 42)
    }

    @Test("PathParameter + QueryParameter + HeaderField 조합")
    func pathParameterWithQueryAndHeaders() throws {
        // Given
        struct ComplexRequest: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/users/{userId}/posts"
            var method: HTTPMethod = .get

            @PathParameter var userId: Int
            @QueryParameter var page: Int?
            @QueryParameter var limit: Int?
            @HeaderField(key: .authorization) var authorization: String?

            init(userId: Int, page: Int?, limit: Int?, authorization: String?) {
                self.userId = userId
                self.page = page
                self.limit = limit
                self.authorization = authorization
            }
        }

        let request = ComplexRequest(userId: 123, page: 2, limit: 50, authorization: "Bearer token")

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let urlString = url.absoluteString

        // PathParameter 확인
        #expect(urlString.contains("/users/123/posts"))

        // QueryParameter 확인
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems
        #expect(queryItems?.contains(where: { $0.name == "page" && $0.value == "2" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "limit" && $0.value == "50" }) == true)

        // HeaderField 확인
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
    }

    @Test("PathParameter + 필수 RequestBody + HeaderField 조합")
    func pathParameterWithRequiredBodyAndHeaders() throws {
        // Given
        struct UpdateRequest: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/posts/{postId}"
            var method: HTTPMethod = .put

            @PathParameter var postId: String
            @RequestBody var body: TestBody // 필수 body
            @HeaderField(key: .authorization) var authorization: String?
            @HeaderField(key: .contentType) var contentType: String? = "application/json"

            init(postId: String, body: TestBody, authorization: String?) {
                self.postId = postId
                self.body = body
                self.authorization = authorization
            }
        }

        let body = TestBody(name: "Updated Post", value: 999)
        let request = UpdateRequest(postId: "post-abc-123", body: body, authorization: "Bearer token")

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)

        // PathParameter 확인
        #expect(url.absoluteString.contains("/posts/post-abc-123"))

        // RequestBody 확인
        let bodyData = try #require(urlRequest.httpBody)
        let decodedBody = try JSONDecoder().decode(TestBody.self, from: bodyData)
        #expect(decodedBody.name == "Updated Post")
        #expect(decodedBody.value == 999)

        // HeaderField 확인
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("모든 PropertyWrapper + 복잡한 시나리오")
    func allPropertyWrappersComplexScenario() throws {
        // Given
        struct ComplexAPIRequest: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/v1/organizations/{orgId}/projects/{projectId}/tasks"
            var method: HTTPMethod = .post

            @PathParameter var orgId: String
            @PathParameter var projectId: Int
            @QueryParameter var assignee: String?
            @QueryParameter var priority: String?
            @QueryParameter(key: "include_archived") var includeArchived: Bool?
            @RequestBody var body: ComplexTestBody
            @HeaderField(key: .authorization) var authorization: String?
            @HeaderField(key: .contentType) var contentType: String? = "application/json"
            @CustomHeader("X-Request-ID") var requestId: String?
            @CustomHeader("X-Client-Version") var clientVersion: String?

            init(
                orgId: String,
                projectId: Int,
                assignee: String?,
                priority: String?,
                includeArchived: Bool?,
                body: ComplexTestBody,
                authorization: String?,
                requestId: String?,
                clientVersion: String?
            ) {
                self.orgId = orgId
                self.projectId = projectId
                self.body = body
                self.assignee = assignee
                self.priority = priority
                self.includeArchived = includeArchived
                self.authorization = authorization
                self.requestId = requestId
                self.clientVersion = clientVersion
            }
        }

        let body = ComplexTestBody(
            id: 1,
            title: "Complex Task",
            metadata: ComplexTestBody.Metadata(createdAt: "2026-01-29", author: "Admin"),
            tags: ["urgent", "backend"],
            isActive: true
        )

        let request = ComplexAPIRequest(
            orgId: "org-xyz",
            projectId: 456,
            assignee: "john@example.com",
            priority: "high",
            includeArchived: false,
            body: body,
            authorization: "Bearer super-secret-token",
            requestId: "req-12345",
            clientVersion: "1.2.3"
        )

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let urlString = url.absoluteString

        // PathParameter 검증 (2개)
        #expect(urlString.contains("/organizations/org-xyz/"))
        #expect(urlString.contains("/projects/456/tasks"))

        // QueryParameter 검증 (3개, 1개는 커스텀 키)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems
        #expect(queryItems?.contains(where: { $0.name == "assignee" && $0.value == "john@example.com" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "priority" && $0.value == "high" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "include_archived" && $0.value == "false" }) == true)

        // RequestBody 검증 (복잡한 구조)
        let bodyData = try #require(urlRequest.httpBody)
        let decodedBody = try JSONDecoder().decode(ComplexTestBody.self, from: bodyData)
        #expect(decodedBody.id == 1)
        #expect(decodedBody.title == "Complex Task")
        #expect(decodedBody.metadata.author == "Admin")
        #expect(decodedBody.tags == ["urgent", "backend"])
        #expect(decodedBody.isActive == true)

        // HeaderField 검증 (2개)
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer super-secret-token")
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")

        // CustomHeader 검증 (2개)
        #expect(urlRequest.value(forHTTPHeaderField: "X-Request-ID") == "req-12345")
        #expect(urlRequest.value(forHTTPHeaderField: "X-Client-Version") == "1.2.3")
    }

    @Test("일부 PropertyWrapper만 사용 (선택적 조합)")
    func partialPropertyWrappers() throws {
        // Given
        struct MinimalRequest: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/ping"
            var method: HTTPMethod = .get

            @HeaderField(key: .authorization) var authorization: String?

            init(authorization: String?) {
                self.authorization = authorization
            }
        }

        let request = MinimalRequest(authorization: "Bearer token")

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.url?.absoluteString == "https://api.example.com/ping")
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(urlRequest.httpBody == nil)
    }

    @Test("PropertyWrapper 우선순위 - HeaderField가 RequestBody의 Content-Type보다 우선")
    func propertyWrapperPriority() throws {
        // Given
        var request = TestRequestWithRequiredBody(body: TestBody(name: "Test", value: 1))
        request.contentType = "application/json; charset=utf-8"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        // HeaderField로 설정한 Content-Type이 우선
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json; charset=utf-8")
    }

    @Test("Edge Case - 모든 옵셔널 값이 nil인 경우")
    func edgeCaseAllOptionalNil() throws {
        // Given
        struct AllOptionalRequest: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/test"
            var method: HTTPMethod = .get

            @QueryParameter var search: String?
            @QueryParameter var limit: Int?
            @HeaderField(key: .authorization) var authorization: String?
            @RequestBody var body: TestBody?

            init() {}
        }

        let request = AllOptionalRequest()

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let url = try #require(urlRequest.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        // 모든 옵셔널이 nil이므로 추가 데이터 없음
        #expect(components?.queryItems == nil || components?.queryItems?.isEmpty == true)
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(urlRequest.httpBody == nil)
    }
}

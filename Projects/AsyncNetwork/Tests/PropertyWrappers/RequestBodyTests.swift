//
//  RequestBodyTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/29.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

/// RequestBody Property Wrapper 테스트
@Suite("RequestBody Tests")
struct RequestBodyTests {
    @Test("RequestBody - JSON 바디 적용")
    func jsonApply() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.body = TestBody(name: "Test", value: 42)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let bodyData = try #require(urlRequest.httpBody)
        let decodedBody = try JSONDecoder().decode(TestBody.self, from: bodyData)

        #expect(decodedBody.name == "Test")
        #expect(decodedBody.value == 42)
    }

    @Test("RequestBody - nil 값은 적용되지 않음")
    func nilValue() throws {
        // Given
        let request = TestRequestWithOptionalBody(body: nil)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.httpBody == nil)
    }

    @Test("RequestBody - Content-Type 자동 설정")
    func contentType() throws {
        // Given
        var request = TestRequest(id: 1, user: "john")
        request.body = TestBody(name: "Test", value: 42)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let contentType = urlRequest.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType?.contains("application/json") == true)
    }

    @Test("RequestBody - 필수 body (Non-optional) 항상 인코딩")
    func required() throws {
        // Given
        let body = TestBody(name: "Required Test", value: 100)
        let request = TestRequestWithRequiredBody(body: body)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let bodyData = try #require(urlRequest.httpBody, "필수 body는 항상 존재해야 함")
        let decodedBody = try JSONDecoder().decode(TestBody.self, from: bodyData)

        #expect(decodedBody.name == "Required Test")
        #expect(decodedBody.value == 100)
    }

    @Test("RequestBody - 옵셔널 body가 nil이면 httpBody도 nil")
    func optionalNil() throws {
        // Given
        let request = TestRequestWithOptionalBody(body: nil)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.httpBody == nil, "옵셔널 body가 nil이면 httpBody도 nil이어야 함")
    }

    @Test("RequestBody - 옵셔널 body에 값이 있으면 인코딩")
    func optionalWithValue() throws {
        // Given
        let body = TestBody(name: "Optional Test", value: 200)
        let request = TestReqWithOptBodyAndContentType(body: body)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let bodyData = try #require(urlRequest.httpBody)
        let decodedBody = try JSONDecoder().decode(TestBody.self, from: bodyData)

        #expect(decodedBody.name == "Optional Test")
        #expect(decodedBody.value == 200)
    }

    @Test("RequestBody - 복잡한 JSON 구조 인코딩")
    func complexJSON() throws {
        // Given
        let complexBody = ComplexTestBody(
            id: 42,
            title: "Complex Test",
            metadata: ComplexTestBody.Metadata(createdAt: "2026-01-29", author: "Test Author"),
            tags: ["swift", "testing", "asyncnetwork"],
            isActive: true
        )

        struct ComplexBodyRequest: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/complex"
            var method: HTTPMethod = .post

            @RequestBody var body: ComplexTestBody

            init(body: ComplexTestBody) {
                self.body = body
            }
        }

        let request = ComplexBodyRequest(body: complexBody)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let bodyData = try #require(urlRequest.httpBody)
        let decodedBody = try JSONDecoder().decode(ComplexTestBody.self, from: bodyData)

        #expect(decodedBody.id == 42)
        #expect(decodedBody.title == "Complex Test")
        #expect(decodedBody.metadata.author == "Test Author")
        #expect(decodedBody.tags.count == 3)
        #expect(decodedBody.tags[0] == "swift")
        #expect(decodedBody.isActive == true)
    }

    @Test("RequestBody - 필수 vs 옵셔널 body 비교")
    func requiredVsOptional() throws {
        // Given
        let body = TestBody(name: "Comparison", value: 50)

        // 필수 body
        let requiredRequest = TestRequestWithRequiredBody(body: body)
        let requiredURLRequest = try requiredRequest.asURLRequest()

        // 옵셔널 body (값 있음, contentType 있음)
        let optionalWithValueRequest = TestReqWithOptBodyAndContentType(body: body)
        let optionalWithValueURLRequest = try optionalWithValueRequest.asURLRequest()

        // 옵셔널 body (nil, contentType 기본값 있음) - 실제 사용 케이스
        let optionalNilWithContentTypeRequest = TestReqWithOptBodyAndContentType(body: nil)
        let optionalNilWithContentTypeURLRequest = try optionalNilWithContentTypeRequest.asURLRequest()

        // 옵셔널 body (nil, contentType 없음)
        let optionalNilRequest = TestRequestWithOptionalBody(body: nil)
        let optionalNilURLRequest = try optionalNilRequest.asURLRequest()

        // Then
        // 필수 body와 옵셔널 body (값 있음)는 httpBody가 존재
        #expect(requiredURLRequest.httpBody != nil)
        #expect(optionalWithValueURLRequest.httpBody != nil)

        // 옵셔널 body (nil)는 httpBody가 nil (Content-Type은 있을 수 있음)
        #expect(optionalNilWithContentTypeURLRequest.httpBody == nil, "contentType이 있어도 body가 nil이면 httpBody는 nil")
        #expect(optionalNilURLRequest.httpBody == nil)

        // 내용 비교
        let requiredDecoded = try JSONDecoder().decode(TestBody.self, from: requiredURLRequest.httpBody!)
        let optionalDecoded = try JSONDecoder().decode(TestBody.self, from: optionalWithValueURLRequest.httpBody!)

        #expect(requiredDecoded.name == optionalDecoded.name)
        #expect(requiredDecoded.value == optionalDecoded.value)
    }

    @Test("RequestBody - 빈 구조체 인코딩")
    func emptyStruct() throws {
        // Given
        struct EmptyBody: Codable, Sendable {}

        struct EmptyBodyRequest: APIRequest {
            var baseURLString: String = "https://api.example.com"
            var path: String = "/empty"
            var method: HTTPMethod = .post

            @RequestBody var body: EmptyBody

            init(body: EmptyBody) {
                self.body = body
            }
        }

        let request = EmptyBodyRequest(body: EmptyBody())

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        let bodyData = try #require(urlRequest.httpBody)
        let jsonString = String(data: bodyData, encoding: .utf8)
        #expect(jsonString == "{}") // 빈 JSON 객체
    }

    @Test("RequestBody + HeaderField 조합")
    func withHeaders() throws {
        // Given
        var request = TestRequest()
        request.body = TestBody(name: "Test", value: 42)
        request.contentType = "application/json; charset=utf-8"

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        #expect(urlRequest.httpBody != nil)
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json; charset=utf-8")
    }
}

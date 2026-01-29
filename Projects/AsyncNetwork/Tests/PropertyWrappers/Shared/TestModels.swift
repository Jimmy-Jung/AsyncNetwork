//
//  TestModels.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/29.
//

@testable import AsyncNetworkCore
import Foundation

// MARK: - Test Bodies

struct TestBody: Codable, Sendable {
    let name: String
    let value: Int
}

struct ComplexTestBody: Codable, Sendable {
    let id: Int
    let title: String
    let metadata: Metadata
    let tags: [String]
    let isActive: Bool

    struct Metadata: Codable, Sendable {
        let createdAt: String
        let author: String
    }
}

// MARK: - Basic Test Requests

struct TestRequest: APIRequest {
    var baseURLString: String = "https://api.example.com"
    var path: String = "/test"
    var method: HTTPMethod = .get

    @QueryParameter var search: String?
    @QueryParameter var limit: Int?
    @QueryParameter var isActive: Bool?

    var id: Int
    var user: String

    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .contentType) var contentType: String?
    @CustomHeader("X-Custom-Header") var customHeader: String?

    @RequestBody var body: TestBody?

    init(id: Int = 0, user: String = "") {
        self.id = id
        self.user = user
    }
}

struct TestRequestWithRequiredQuery: APIRequest {
    var baseURLString: String = "https://api.example.com"
    var path: String = "/test"
    var method: HTTPMethod = .get

    @QueryParameter var userId: Int?
    @QueryParameter var name: String?
    @QueryParameter var page: Int?

    init(userId: Int, name: String, page: Int? = nil) {
        _userId = QueryParameter(wrappedValue: userId)
        _name = QueryParameter(wrappedValue: name)
        _page = QueryParameter(wrappedValue: page)
    }
}

struct TestRequestWithCustomKeyQuery: APIRequest {
    var baseURLString: String = "https://api.example.com"
    var path: String = "/search"
    var method: HTTPMethod = .get

    @QueryParameter(key: "q") var searchTerm: String?
    @QueryParameter(key: "per_page") var itemsPerPage: Int?

    init() {}
}

struct TestRequestWithPathParameter: APIRequest {
    var baseURLString: String = "https://api.example.com"
    var path: String = "/users/{userId}/posts/{postId}"
    var method: HTTPMethod = .get

    @PathParameter var userId: Int
    @PathParameter var postId: String

    init(userId: Int, postId: String) {
        self.userId = userId
        self.postId = postId
    }
}

struct TestRequestWithEncodedPathPlaceholder: APIRequest {
    var baseURLString: String = "https://api.example.com"
    var path: String = "/items/%7BitemId%7D/details" // URL 인코딩된 placeholder
    var method: HTTPMethod = .get

    @PathParameter var itemId: String

    init(itemId: String) {
        self.itemId = itemId
    }
}

struct TestRequestWithRequiredBody: APIRequest {
    var baseURLString: String = "https://api.example.com"
    var path: String = "/users"
    var method: HTTPMethod = .post

    @RequestBody var body: TestBody // 필수 body (Non-optional)
    @HeaderField(key: .contentType) var contentType: String? = "application/json"

    init(body: TestBody) {
        self.body = body
    }
}

struct TestRequestWithOptionalBody: APIRequest {
    var baseURLString: String = "https://api.example.com"
    var path: String = "/users"
    var method: HTTPMethod = .patch

    @RequestBody var body: TestBody? // 옵셔널 body

    init(body: TestBody? = nil) {
        self.body = body
    }
}

struct TestReqWithOptBodyAndContentType: APIRequest {
    var baseURLString: String = "https://api.example.com"
    var path: String = "/users"
    var method: HTTPMethod = .patch

    @RequestBody var body: TestBody? // 옵셔널 body
    @HeaderField(key: .contentType) var contentType: String? = "application/json"

    init(body: TestBody? = nil) {
        self.body = body
    }
}

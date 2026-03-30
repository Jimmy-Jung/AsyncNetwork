//
//  DemoRequests.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import AsyncNetwork
import Foundation

struct GetPostsRequest: APIRequest {
    typealias Response = [DemoPost]

    let baseURLString = "https://jsonplaceholder.typicode.com"
    let path = "/posts"
    let method: HTTPMethod = .get

    @QueryParameter var userId: Int?
    @QueryParameter(key: "_limit") var limit: Int?

    init(userId: Int? = nil, limit: Int? = nil) {
        self.userId = userId
        self.limit = limit
    }
}

struct GetPostDetailRequest: APIRequest {
    typealias Response = DemoPost

    let baseURLString = "https://jsonplaceholder.typicode.com"
    let path = "/posts/{id}"
    let method: HTTPMethod = .get

    @PathParameter var id: Int
}

struct CreatePostRequest: APIRequest {
    typealias Response = DemoPost

    let baseURLString = "https://jsonplaceholder.typicode.com"
    let path = "/posts"
    let method: HTTPMethod = .post

    @RequestBody var body: DemoCreatePostBody

    init(body: DemoCreatePostBody) {
        self.body = body
    }
}

struct AuthenticatedPostsRequest: APIRequest {
    typealias Response = [DemoPost]

    let baseURLString = "https://jsonplaceholder.typicode.com"
    let path = "/posts"
    let method: HTTPMethod = .get

    @QueryParameter(key: "_limit") var limit: Int?
    @HeaderField(key: .authorization) var authorization: String?

    init(limit: Int? = nil, authorization: String? = nil) {
        self.limit = limit
        self.authorization = authorization
    }
}

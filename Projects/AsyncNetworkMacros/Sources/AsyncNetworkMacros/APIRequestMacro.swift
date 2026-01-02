//
//  APIRequestMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/01.
//

import AsyncNetworkCore

/// @APIRequest 매크로 선언
///
/// **사용 예시:**
/// ```swift
/// @APIRequest(
///     response: [Post].self,
///     title: "Get all posts",
///     baseURL: "https://jsonplaceholder.typicode.com",
///     path: "/posts",
///     method: "get",
///     tags: ["Posts", "Read"]
/// )
/// struct GetPostsRequest {
///     @QueryParameter var userId: Int?
/// }
/// ```
@attached(member, names:
    named(Response),
    named(baseURLString),
    named(path),
    named(method),
    named(headers),
    named(task),
    named(metadata))
@attached(extension, conformances: APIRequest)
public macro APIRequest(
    response: Any.Type,
    title: String,
    description: String = "",
    baseURL: String? = nil,
    path: String,
    method: String,
    headers: [String: String] = [:],
    tags: [String] = [],
    requestBodyExample: String? = nil,
    responseStructure: String? = nil,
    responseExample: String? = nil
) = #externalMacro(
    module: "AsyncNetworkMacrosImpl",
    type: "APIRequestMacroImpl"
)

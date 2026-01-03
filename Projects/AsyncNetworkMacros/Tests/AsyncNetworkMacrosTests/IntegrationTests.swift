//
//  IntegrationTests.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/03.
//

// Swift Macro는 macOS에서만 빌드 가능하므로 테스트도 macOS 전용
#if os(macOS)

    import SwiftSyntax
    import SwiftSyntaxMacros
    import SwiftSyntaxMacrosTestSupport
    import Testing

    @testable import AsyncNetworkMacrosImpl

    // MARK: - IntegrationTests

    @Suite("APIRequest Macro - Integration Tests")
    struct IntegrationTests {
        let testMacros: [String: Macro.Type] = [
            "APIRequest": APIRequestMacroImpl.self,
        ]

        @Test("실제 CRUD API 시나리오 - Create")
        func realWorldCreateScenario() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostResponse.self,
                    title: "Create a new post",
                    description: "Creates a new blog post with the provided content",
                    baseURL: "https://jsonplaceholder.typicode.com",
                    path: "/posts",
                    method: .post,
                    tags: ["Posts", "Write", "CRUD"],
                    requestBodyExample: "{\\"title\\": \\"foo\\", \\"body\\": \\"bar\\", \\"userId\\": 1}",
                    responseExample: "{\\"id\\": 101, \\"title\\": \\"foo\\", \\"body\\": \\"bar\\", \\"userId\\": 1}"
                )
                struct CreatePostRequest {
                    @HeaderField(key: .contentType) var contentType: String? = "application/json"
                    @HeaderField(key: .authorization) var authorization: String?
                    @CustomHeader("X-Request-ID") var requestId: String?
                    @RequestBody var body: CreatePostBody
                }
                """,
                expandedSource: """
                struct CreatePostRequest {
                    @HeaderField(key: .contentType) var contentType: String? = "application/json"
                    @HeaderField(key: .authorization) var authorization: String?
                    @CustomHeader("X-Request-ID") var requestId: String?
                    @RequestBody var body: CreatePostBody

                    typealias Response = PostResponse

                    var baseURLString: String {
                        "https://jsonplaceholder.typicode.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .post
                    }
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "CreatePostRequest",
                            title: "Create a new post",
                            description: "Creates a new blog post with the provided content",
                            method: "post",
                            path: "/posts",
                            baseURLString: "https://jsonplaceholder.typicode.com",
                            headers: [
                                "Content-Type": "contentType",
                                "Authorization": "authorization",
                                "X-Request-ID": "requestId"
                            ],
                            tags: ["Posts", "Write", "CRUD"],
                            parameters: [
                                ParameterInfo(
                                    id: "body",
                                    name: "body",
                                    type: "CreatePostBody",
                                    location: .body,
                                    isRequired: true
                                )
                            ],
                            requestBodyExample: "{\\"title\\": \\"foo\\", \\"body\\": \\"bar\\", \\"userId\\": 1}",
                            responseExample: "{\\"id\\": 101, \\"title\\": \\"foo\\", \\"body\\": \\"bar\\", \\"userId\\": 1}",
                            responseTypeName: "PostResponse"
                        )
                    }
                }

                extension CreatePostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("실제 CRUD API 시나리오 - Read with Pagination")
        func realWorldReadWithPaginationScenario() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PaginatedPostsResponse.self,
                    title: "Get paginated posts",
                    description: "Retrieves a paginated list of blog posts",
                    baseURL: "https://jsonplaceholder.typicode.com",
                    path: "/posts",
                    method: .get,
                    tags: ["Posts", "Read", "Pagination"],
                    responseExample: "{\\"data\\": [], \\"page\\": 1, \\"total\\": 100}"
                )
                struct GetPostsRequest {
                    @HeaderField(key: .authorization) var authorization: String?
                    @QueryParameter var page: Int = 1
                    @QueryParameter var limit: Int = 20
                    @QueryParameter var sort: String?
                    @QueryParameter var filter: String?
                }
                """,
                expandedSource: """
                struct GetPostsRequest {
                    @HeaderField(key: .authorization) var authorization: String?
                    @QueryParameter var page: Int = 1
                    @QueryParameter var limit: Int = 20
                    @QueryParameter var sort: String?
                    @QueryParameter var filter: String?

                    typealias Response = PaginatedPostsResponse

                    var baseURLString: String {
                        "https://jsonplaceholder.typicode.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "Get paginated posts",
                            description: "Retrieves a paginated list of blog posts",
                            method: "get",
                            path: "/posts",
                            baseURLString: "https://jsonplaceholder.typicode.com",
                            headers: [
                                "Authorization": "authorization"
                            ],
                            tags: ["Posts", "Read", "Pagination"],
                            parameters: [
                                ParameterInfo(
                                    id: "page",
                                    name: "page",
                                    type: "Int",
                                    location: .query,
                                    isRequired: true
                                ),
                                ParameterInfo(
                                    id: "limit",
                                    name: "limit",
                                    type: "Int",
                                    location: .query,
                                    isRequired: true
                                ),
                                ParameterInfo(
                                    id: "sort",
                                    name: "sort",
                                    type: "String?",
                                    location: .query,
                                    isRequired: false
                                ),
                                ParameterInfo(
                                    id: "filter",
                                    name: "filter",
                                    type: "String?",
                                    location: .query,
                                    isRequired: false
                                )
                            ],
                            requestBodyExample: nil,
                            responseExample: "{\\"data\\": [], \\"page\\": 1, \\"total\\": 100}",
                            responseTypeName: "PaginatedPostsResponse"
                        )
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("실제 CRUD API 시나리오 - Update")
        func realWorldUpdateScenario() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostResponse.self,
                    title: "Update a post",
                    description: "Updates an existing blog post",
                    baseURL: "https://jsonplaceholder.typicode.com",
                    path: "/posts/{id}",
                    method: .put,
                    tags: ["Posts", "Write", "CRUD"],
                    requestBodyExample: "{\\"title\\": \\"updated\\", \\"body\\": \\"updated content\\"}",
                    responseExample: "{\\"id\\": 1, \\"title\\": \\"updated\\", \\"body\\": \\"updated content\\"}"
                )
                struct UpdatePostRequest {
                    @PathParameter var id: Int
                    @HeaderField(key: .contentType) var contentType: String? = "application/json"
                    @HeaderField(key: .authorization) var authorization: String?
                    @RequestBody var body: UpdatePostBody
                }
                """,
                expandedSource: """
                struct UpdatePostRequest {
                    @PathParameter var id: Int
                    @HeaderField(key: .contentType) var contentType: String? = "application/json"
                    @HeaderField(key: .authorization) var authorization: String?
                    @RequestBody var body: UpdatePostBody

                    typealias Response = PostResponse

                    var baseURLString: String {
                        "https://jsonplaceholder.typicode.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .put
                    }
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "UpdatePostRequest",
                            title: "Update a post",
                            description: "Updates an existing blog post",
                            method: "put",
                            path: "/posts/{id}",
                            baseURLString: "https://jsonplaceholder.typicode.com",
                            headers: [
                                "Content-Type": "contentType",
                                "Authorization": "authorization"
                            ],
                            tags: ["Posts", "Write", "CRUD"],
                            parameters: [
                                ParameterInfo(
                                    id: "id",
                                    name: "id",
                                    type: "Int",
                                    location: .path,
                                    isRequired: true
                                ),
                                ParameterInfo(
                                    id: "body",
                                    name: "body",
                                    type: "UpdatePostBody",
                                    location: .body,
                                    isRequired: true
                                )
                            ],
                            requestBodyExample: "{\\"title\\": \\"updated\\", \\"body\\": \\"updated content\\"}",
                            responseExample: "{\\"id\\": 1, \\"title\\": \\"updated\\", \\"body\\": \\"updated content\\"}",
                            responseTypeName: "PostResponse"
                        )
                    }
                }

                extension UpdatePostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("실제 CRUD API 시나리오 - Delete")
        func realWorldDeleteScenario() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: EmptyResponse.self,
                    title: "Delete a post",
                    description: "Deletes a blog post by ID",
                    baseURL: "https://jsonplaceholder.typicode.com",
                    path: "/posts/{id}",
                    method: .delete,
                    tags: ["Posts", "Write", "CRUD"]
                )
                struct DeletePostRequest {
                    @PathParameter var id: Int
                    @HeaderField(key: .authorization) var authorization: String?
                }
                """,
                expandedSource: """
                struct DeletePostRequest {
                    @PathParameter var id: Int
                    @HeaderField(key: .authorization) var authorization: String?

                    typealias Response = EmptyResponse

                    var baseURLString: String {
                        "https://jsonplaceholder.typicode.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .delete
                    }
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "DeletePostRequest",
                            title: "Delete a post",
                            description: "Deletes a blog post by ID",
                            method: "delete",
                            path: "/posts/{id}",
                            baseURLString: "https://jsonplaceholder.typicode.com",
                            headers: [
                                "Authorization": "authorization"
                            ],
                            tags: ["Posts", "Write", "CRUD"],
                            parameters: [
                                ParameterInfo(
                                    id: "id",
                                    name: "id",
                                    type: "Int",
                                    location: .path,
                                    isRequired: true
                                )
                            ],
                            requestBodyExample: nil,
                            responseExample: nil,
                            responseTypeName: "EmptyResponse"
                        )
                    }
                }

                extension DeletePostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("실제 중첩 리소스 시나리오 - Comments on Post")
        func realWorldNestedResourceScenario() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: [CommentResponse].self,
                    title: "Get post comments",
                    description: "Retrieves all comments for a specific post",
                    baseURL: "https://jsonplaceholder.typicode.com",
                    path: "/posts/{postId}/comments",
                    method: .get,
                    tags: ["Posts", "Comments", "Read", "Nested"]
                )
                struct GetPostCommentsRequest {
                    @PathParameter var postId: Int
                    @QueryParameter var page: Int?
                    @QueryParameter var limit: Int?
                }
                """,
                expandedSource: """
                struct GetPostCommentsRequest {
                    @PathParameter var postId: Int
                    @QueryParameter var page: Int?
                    @QueryParameter var limit: Int?

                    typealias Response = [CommentResponse]

                    var baseURLString: String {
                        "https://jsonplaceholder.typicode.com"
                    }

                    var path: String {
                        "/posts/{postId}/comments"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostCommentsRequest",
                            title: "Get post comments",
                            description: "Retrieves all comments for a specific post",
                            method: "get",
                            path: "/posts/{postId}/comments",
                            baseURLString: "https://jsonplaceholder.typicode.com",
                            headers: nil,
                            tags: ["Posts", "Comments", "Read", "Nested"],
                            parameters: [
                                ParameterInfo(
                                    id: "postId",
                                    name: "postId",
                                    type: "Int",
                                    location: .path,
                                    isRequired: true
                                ),
                                ParameterInfo(
                                    id: "page",
                                    name: "page",
                                    type: "Int?",
                                    location: .query,
                                    isRequired: false
                                ),
                                ParameterInfo(
                                    id: "limit",
                                    name: "limit",
                                    type: "Int?",
                                    location: .query,
                                    isRequired: false
                                )
                            ],
                            requestBodyExample: nil,
                            responseExample: nil,
                            responseTypeName: "[CommentResponse]"
                        )
                    }
                }

                extension GetPostCommentsRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("실제 검색 API 시나리오")
        func realWorldSearchScenario() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: SearchResultResponse.self,
                    title: "Search posts",
                    description: "Searches for posts matching the query",
                    baseURL: "https://jsonplaceholder.typicode.com",
                    path: "/search/posts",
                    method: .get,
                    tags: ["Search", "Posts", "Read"]
                )
                struct SearchPostsRequest {
                    @QueryParameter var q: String
                    @QueryParameter var category: String?
                    @QueryParameter var tags: String?
                    @QueryParameter var author: String?
                    @QueryParameter var sort: String?
                    @QueryParameter var order: String?
                    @QueryParameter var page: Int?
                    @QueryParameter var limit: Int?
                }
                """,
                expandedSource: """
                struct SearchPostsRequest {
                    @QueryParameter var q: String
                    @QueryParameter var category: String?
                    @QueryParameter var tags: String?
                    @QueryParameter var author: String?
                    @QueryParameter var sort: String?
                    @QueryParameter var order: String?
                    @QueryParameter var page: Int?
                    @QueryParameter var limit: Int?

                    typealias Response = SearchResultResponse

                    var baseURLString: String {
                        "https://jsonplaceholder.typicode.com"
                    }

                    var path: String {
                        "/search/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                    static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "SearchPostsRequest",
                            title: "Search posts",
                            description: "Searches for posts matching the query",
                            method: "get",
                            path: "/search/posts",
                            baseURLString: "https://jsonplaceholder.typicode.com",
                            headers: nil,
                            tags: ["Search", "Posts", "Read"],
                            parameters: [
                                ParameterInfo(
                                    id: "q",
                                    name: "q",
                                    type: "String",
                                    location: .query,
                                    isRequired: true
                                ),
                                ParameterInfo(
                                    id: "category",
                                    name: "category",
                                    type: "String?",
                                    location: .query,
                                    isRequired: false
                                ),
                                ParameterInfo(
                                    id: "tags",
                                    name: "tags",
                                    type: "String?",
                                    location: .query,
                                    isRequired: false
                                ),
                                ParameterInfo(
                                    id: "author",
                                    name: "author",
                                    type: "String?",
                                    location: .query,
                                    isRequired: false
                                ),
                                ParameterInfo(
                                    id: "sort",
                                    name: "sort",
                                    type: "String?",
                                    location: .query,
                                    isRequired: false
                                ),
                                ParameterInfo(
                                    id: "order",
                                    name: "order",
                                    type: "String?",
                                    location: .query,
                                    isRequired: false
                                ),
                                ParameterInfo(
                                    id: "page",
                                    name: "page",
                                    type: "Int?",
                                    location: .query,
                                    isRequired: false
                                ),
                                ParameterInfo(
                                    id: "limit",
                                    name: "limit",
                                    type: "Int?",
                                    location: .query,
                                    isRequired: false
                                )
                            ],
                            requestBodyExample: nil,
                            responseExample: nil,
                            responseTypeName: "SearchResultResponse"
                        )
                    }
                }

                extension SearchPostsRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }
    }

#endif // os(macOS)

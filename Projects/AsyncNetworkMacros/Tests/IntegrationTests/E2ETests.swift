//
//  E2ETests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/13.
//

#if os(macOS)

    import SwiftSyntaxMacros
    import SwiftSyntaxMacrosTestSupport
    import Testing

    @testable import AsyncNetworkMacros
    @testable import AsyncNetworkMacrosImpl

    @Suite("E2E Tests - Real-world Scenarios")
    struct E2ETests {
        @Test("실제 사용 케이스 - JSONPlaceholder API")
        func jSONPlaceholderAPI() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get Post by ID",
                    description: "Retrieve a single post from JSONPlaceholder",
                    baseURL: "https://jsonplaceholder.typicode.com",
                    path: "/posts/{id}",
                    method: .get,
                    tags: ["Posts"]
                )
                struct GetPostRequest {
                    @PathParameter var id: Int
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                    @PathParameter var id: Int

                    public typealias Response = Post

                    public var baseURLString: String {
                        "https://jsonplaceholder.typicode.com"
                    }

                    public var method: HTTPMethod {
                        .get
                    }

                    public var path: String {
                        "/posts/\\(id)"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: "Get Post by ID",
                            description: "Retrieve a single post from JSONPlaceholder",
                            method: "GET",
                            path: "/posts/{id}",
                            tags: ["Posts"],
                            parameters: [
                                .path(name: "id", type: "Int", required: true)
                            ]
                        )
                    }
                }

                extension GetPostRequest: APIRequest {
                }
                """,
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("실제 사용 케이스 - GitHub API")
        func gitHubAPI() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Repository.self,
                    title: "Get Repository",
                    description: "Fetch repository information",
                    baseURL: "https://api.github.com",
                    path: "/repos/{owner}/{repo}",
                    method: .get,
                    tags: ["Repositories"]
                )
                struct GetRepositoryRequest {
                    @PathParameter var owner: String
                    @PathParameter var repo: String
                    @HeaderField(.authorization) var token: String?
                    @QueryParameter var page: Int = 1
                }
                """,
                expandedSource: """
                struct GetRepositoryRequest {
                    @PathParameter var owner: String
                    @PathParameter var repo: String
                    @HeaderField(.authorization) var token: String?
                    @QueryParameter var page: Int = 1

                    public typealias Response = Repository

                    public var baseURLString: String {
                        "https://api.github.com"
                    }

                    public var method: HTTPMethod {
                        .get
                    }

                    public var path: String {
                        "/repos/\\(owner)/\\(repo)"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: "Get Repository",
                            description: "Fetch repository information",
                            method: "GET",
                            path: "/repos/{owner}/{repo}",
                            tags: ["Repositories"],
                            parameters: [
                                .path(name: "owner", type: "String", required: true),
                                .path(name: "repo", type: "String", required: true),
                                .header(name: "authorization", type: "String", required: false),
                                .query(name: "page", type: "Int", required: true, defaultValue: "1")
                            ]
                        )
                    }
                }

                extension GetRepositoryRequest: APIRequest {
                }
                """,
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("실제 사용 케이스 - RESTful CRUD API")
        func rESTfulCRUDAPI() {
            // CREATE
            assertMacroExpansion(
                """
                @APIRequest(
                    response: User.self,
                    title: "Create User",
                    description: "Create a new user account",
                    baseURL: "https://api.myapp.com",
                    path: "/v1/users",
                    method: .post,
                    tags: ["Users", "Authentication"]
                )
                struct CreateUserRequest {
                    @RequestBody var user: CreateUserBody
                    @CustomHeader(key: "X-API-Key") var apiKey: String
                    @HeaderField(.contentType) var contentType: String = "application/json"
                }
                """,
                expandedSource: """
                struct CreateUserRequest {
                    @RequestBody var user: CreateUserBody
                    @CustomHeader(key: "X-API-Key") var apiKey: String
                    @HeaderField(.contentType) var contentType: String = "application/json"

                    public typealias Response = User

                    public var baseURLString: String {
                        "https://api.myapp.com"
                    }

                    public var method: HTTPMethod {
                        .post
                    }

                    public var path: String {
                        "/v1/users"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: "Create User",
                            description: "Create a new user account",
                            method: "POST",
                            path: "/v1/users",
                            tags: ["Users", "Authentication"],
                            parameters: [
                                .body(type: "CreateUserBody"),
                                .header(name: "X-API-Key", type: "String", required: true),
                                .header(name: "contentType", type: "String", required: true, defaultValue: "\\"application/json\\"")
                            ]
                        )
                    }
                }

                extension CreateUserRequest: APIRequest {
                }
                """,
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("실제 사용 케이스 - 검색 API with multiple query params")
        func searchAPIWithMultipleQueryParams() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: SearchResults.self,
                    title: "Search Products",
                    description: "Search products with filters",
                    baseURL: "https://api.shop.com",
                    path: "/v2/products/search",
                    method: .get,
                    tags: ["Products", "Search"]
                )
                struct SearchProductsRequest {
                    @QueryParameter var query: String
                    @QueryParameter var category: String?
                    @QueryParameter var minPrice: Double?
                    @QueryParameter var maxPrice: Double?
                    @QueryParameter var page: Int = 1
                    @QueryParameter var limit: Int = 20
                    @QueryParameter var sortBy: String = "relevance"
                }
                """,
                expandedSource: """
                struct SearchProductsRequest {
                    @QueryParameter var query: String
                    @QueryParameter var category: String?
                    @QueryParameter var minPrice: Double?
                    @QueryParameter var maxPrice: Double?
                    @QueryParameter var page: Int = 1
                    @QueryParameter var limit: Int = 20
                    @QueryParameter var sortBy: String = "relevance"

                    public typealias Response = SearchResults

                    public var baseURLString: String {
                        "https://api.shop.com"
                    }

                    public var method: HTTPMethod {
                        .get
                    }

                    public var path: String {
                        "/v2/products/search"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: "Search Products",
                            description: "Search products with filters",
                            method: "GET",
                            path: "/v2/products/search",
                            tags: ["Products", "Search"],
                            parameters: [
                                .query(name: "query", type: "String", required: true),
                                .query(name: "category", type: "String", required: false),
                                .query(name: "minPrice", type: "Double", required: false),
                                .query(name: "maxPrice", type: "Double", required: false),
                                .query(name: "page", type: "Int", required: true, defaultValue: "1"),
                                .query(name: "limit", type: "Int", required: true, defaultValue: "20"),
                                .query(name: "sortBy", type: "String", required: true, defaultValue: "\\"relevance\\"")
                            ]
                        )
                    }
                }

                extension SearchProductsRequest: APIRequest {
                }
                """,
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("실제 사용 케이스 - File Upload API")
        func fileUploadAPI() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: UploadResponse.self,
                    title: "Upload Avatar",
                    description: "Upload user avatar image",
                    baseURL: "https://api.myapp.com",
                    path: "/v1/users/{userId}/avatar",
                    method: .post,
                    tags: ["Users", "Media"]
                )
                struct UploadAvatarRequest {
                    @PathParameter var userId: String
                    @FormData var imageData: Data
                    @CustomHeader(key: "X-API-Key") var apiKey: String
                }
                """,
                expandedSource: """
                struct UploadAvatarRequest {
                    @PathParameter var userId: String
                    @FormData var imageData: Data
                    @CustomHeader(key: "X-API-Key") var apiKey: String

                    public typealias Response = UploadResponse

                    public var baseURLString: String {
                        "https://api.myapp.com"
                    }

                    public var method: HTTPMethod {
                        .post
                    }

                    public var path: String {
                        "/v1/users/\\(userId)/avatar"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: "Upload Avatar",
                            description: "Upload user avatar image",
                            method: "POST",
                            path: "/v1/users/{userId}/avatar",
                            tags: ["Users", "Media"],
                            parameters: [
                                .path(name: "userId", type: "String", required: true),
                                .formData(name: "imageData", type: "Data"),
                                .header(name: "X-API-Key", type: "String", required: true)
                            ]
                        )
                    }
                }

                extension UploadAvatarRequest: APIRequest {
                }
                """,
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }

        @Test("실제 사용 케이스 - Pagination API")
        func paginationAPI() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PaginatedResponse<Article>.self,
                    title: "List Articles",
                    description: "Get paginated list of articles",
                    baseURL: "https://api.blog.com",
                    path: "/v1/articles",
                    method: .get,
                    tags: ["Articles"]
                )
                struct ListArticlesRequest {
                    @QueryParameter var page: Int = 1
                    @QueryParameter var perPage: Int = 10
                    @QueryParameter var sortBy: String?
                    @QueryParameter var order: String = "desc"
                    @QueryParameter var tag: String?
                }
                """,
                expandedSource: """
                struct ListArticlesRequest {
                    @QueryParameter var page: Int = 1
                    @QueryParameter var perPage: Int = 10
                    @QueryParameter var sortBy: String?
                    @QueryParameter var order: String = "desc"
                    @QueryParameter var tag: String?

                    public typealias Response = PaginatedResponse<Article>

                    public var baseURLString: String {
                        "https://api.blog.com"
                    }

                    public var method: HTTPMethod {
                        .get
                    }

                    public var path: String {
                        "/v1/articles"
                    }

                    public var metadata: EndpointMetadata {
                        EndpointMetadata(
                            title: "List Articles",
                            description: "Get paginated list of articles",
                            method: "GET",
                            path: "/v1/articles",
                            tags: ["Articles"],
                            parameters: [
                                .query(name: "page", type: "Int", required: true, defaultValue: "1"),
                                .query(name: "perPage", type: "Int", required: true, defaultValue: "10"),
                                .query(name: "sortBy", type: "String", required: false),
                                .query(name: "order", type: "String", required: true, defaultValue: "\\"desc\\""),
                                .query(name: "tag", type: "String", required: false)
                            ]
                        )
                    }
                }

                extension ListArticlesRequest: APIRequest {
                }
                """,
                macros: ["APIRequest": APIRequestMacroImpl.self]
            )
        }
    }

#endif // os(macOS)

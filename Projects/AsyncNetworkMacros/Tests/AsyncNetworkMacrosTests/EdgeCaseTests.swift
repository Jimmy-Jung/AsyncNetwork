//
//  EdgeCaseTests.swift
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

    // MARK: - EdgeCaseTests

    @Suite("APIRequest Macro - Edge Case Tests")
    struct EdgeCaseTests {
        let testMacros: [String: Macro.Type] = [
            "APIRequest": APIRequestMacroImpl.self,
        ]

        @Test("빈 경로 - root path")
        func emptyPath() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: RootResponse.self,
                    baseURL: "https://api.example.com",
                    path: "/",
                    method: .get
                )
                struct GetRootRequest {
                }
                """,
                expandedSource: """
                struct GetRootRequest {

                    typealias Response = RootResponse

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetRootRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("매우 긴 경로")
        func longPath() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Data.self,
                    baseURL: "https://api.example.com",
                    path: "/api/v1/organizations/{orgId}/teams/{teamId}/members/{memberId}/permissions/{permissionId}/details",
                    method: .get
                )
                struct GetDeepNestedResourceRequest {
                    @PathParameter var orgId: String
                    @PathParameter var teamId: String
                    @PathParameter var memberId: String
                    @PathParameter var permissionId: String
                }
                """,
                expandedSource: """
                struct GetDeepNestedResourceRequest {
                    @PathParameter var orgId: String
                    @PathParameter var teamId: String
                    @PathParameter var memberId: String
                    @PathParameter var permissionId: String

                    typealias Response = Data

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/api/v1/organizations/{orgId}/teams/{teamId}/members/{memberId}/permissions/{permissionId}/details"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetDeepNestedResourceRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("특수문자가 포함된 경로")
        func pathWithSpecialCharacters() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: SearchResult.self,
                    baseURL: "https://api.example.com",
                    path: "/search?q={query}&sort=desc",
                    method: .get
                )
                struct SearchRequest {
                }
                """,
                expandedSource: """
                struct SearchRequest {

                    typealias Response = SearchResult

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/search?q={query}&sort=desc"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension SearchRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("매우 긴 description과 많은 tags")
        func longDescriptionManyTags() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Complex API Endpoint",
                    description: "This is a very long description that spans multiple lines and contains detailed information about the API endpoint including its purpose, usage, parameters, response format, error handling, authentication requirements, rate limiting, and various other important details that developers need to know.",
                    baseURL: "https://api.example.com",
                    path: "/posts/1",
                    method: .get,
                    tags: ["Posts", "Read", "Public", "Cached", "Versioned", "Paginated", "Filtered", "Sorted", "Archived"]
                )
                struct GetPostRequest {
                }
                """,
                expandedSource: """
                struct GetPostRequest {

                    typealias Response = Post

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/1"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetPostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("모든 선택적 파라미터 생략")
        func allOptionalParametersOmitted() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = Post

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("baseURL이 복잡한 표현식")
        func complexBaseURLExpression() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: ProcessInfo.processInfo.environment["API_URL"] ?? "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = Post

                    var baseURLString: String {
                        ProcessInfo.processInfo.environment["API_URL"] ?? "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("복잡한 제네릭 응답 타입")
        func complexGenericResponseType() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Result<[Post], NetworkError>.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                struct GetPostsRequest {
                }
                """,
                expandedSource: """
                struct GetPostsRequest {

                    typealias Response = Result<[Post], NetworkError>

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetPostsRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("여러 선택적 경로 파라미터")
        func multipleOptionalPathParameters() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Resource.self,
                    baseURL: "https://api.example.com",
                    path: "/api/{version?}/{resource?}/{id?}",
                    method: .get
                )
                struct GetResourceRequest {
                    @PathParameter var version: String?
                    @PathParameter var resource: String?
                    @PathParameter var id: String?
                }
                """,
                expandedSource: """
                struct GetResourceRequest {
                    @PathParameter var version: String?
                    @PathParameter var resource: String?
                    @PathParameter var id: String?

                    typealias Response = Resource

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        var result = ""
                        result += "/api"
                        if let version = self.version {
                            result += "/\\(version)"
                        }
                        if let resource = self.resource {
                            result += "/\\(resource)"
                        }
                        if let id = self.id {
                            result += "/\\(id)"
                        }
                        return result
                    }

                    var method: HTTPMethod {
                        .get
                    }
                }

                extension GetResourceRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("모든 PropertyWrapper 타입 혼합")
        func allPropertyWrappersMixed() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .put
                )
                struct UpdatePostRequest {
                    @PathParameter var id: Int
                    @QueryParameter var notify: Bool?
                    @HeaderField(key: .authorization) var authorization: String?
                    @CustomHeader("X-Request-ID") var requestId: String?
                    @RequestBody var body: PostBody
                }
                """,
                expandedSource: """
                struct UpdatePostRequest {
                    @PathParameter var id: Int
                    @QueryParameter var notify: Bool?
                    @HeaderField(key: .authorization) var authorization: String?
                    @CustomHeader("X-Request-ID") var requestId: String?
                    @RequestBody var body: PostBody

                    typealias Response = Post

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .put
                    }
                }

                extension UpdatePostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }

        @Test("responseExample과 requestBodyExample 모두 포함")
        func bothExamplesIncluded() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .post,
                    requestBodyExample: "{\\"title\\": \\"Hello\\", \\"content\\": \\"World\\"}",
                    responseExample: "{\\"id\\": 123, \\"title\\": \\"Hello\\", \\"content\\": \\"World\\"}"
                )
                struct CreatePostRequest {
                    @RequestBody var body: PostBody
                }
                """,
                expandedSource: """
                struct CreatePostRequest {
                    @RequestBody var body: PostBody

                    typealias Response = Post

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .post
                    }
                }

                extension CreatePostRequest: APIRequest {
                }
                """,
                macros: testMacros
            )
        }
    }

#endif // os(macOS)

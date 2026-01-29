//
//  MacroCompositionTests.swift
//  AsyncNetworkMacrosTests
//
//  Created by jimmy on 2026/01/12.
//

#if os(macOS)

    import SwiftSyntax
    import SwiftSyntaxMacros
    import SwiftSyntaxMacrosTestSupport
    import Testing

    @testable import AsyncNetworkMacrosImpl

    @Suite("매크로 조합 테스트")
    struct MacroCompositionTests {
        let testMacros: [String: Macro.Type] = [
            "APIRequest": APIRequestMacroImpl.self,
            "APIDocument": APIDocumentMacroImpl.self,
            "APITestable": APITestableMacroImpl.self,
            "QueryParameter": QueryParameterMacroStub.self, // Stub for testing
        ]

        @Test("@APIRequest + @APIDocument 조합")
        func apiRequestWithDocument() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .get
                )
                @APIDocument(
                    title: "Get all posts",
                    description: "Retrieve a list of posts",
                    tags: ["Posts"]
                )
                struct GetPostsRequest {
                    @QueryParameter var userId: Int?
                }
                """,
                expandedSource: """
                struct GetPostsRequest {
                    @QueryParameter var userId: Int?

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostsRequest",
                            title: "Get all posts",
                            description: "Retrieve a list of posts",
                            method: "GET",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: ["userId"],
                            responseTypeName: "PostDTO"
                        )
                    }

                    public init(userId: Int? = nil) {
                        self._userId = QueryParameter(wrappedValue: userId)
                    }
                }

                extension GetPostsRequest: APIRequest {
                }

                extension GetPostsRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }
        
        @Test("@APIDocument - POST 메서드는 대문자로 생성")
        func apiDocumentPostMethodUppercase() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts",
                    method: .post
                )
                @APIDocument(
                    title: "Create post",
                    description: "Create a new post",
                    tags: ["Posts"]
                )
                struct CreatePostRequest {
                }
                """,
                expandedSource: """
                struct CreatePostRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts"
                    }

                    var method: HTTPMethod {
                        .post
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "CreatePostRequest",
                            title: "Create post",
                            description: "Create a new post",
                            method: "POST",
                            path: "/posts",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension CreatePostRequest: APIRequest {
                }

                extension CreatePostRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }
        
        @Test("@APIDocument - PATCH 메서드는 대문자로 생성")
        func apiDocumentPatchMethodUppercase() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .patch
                )
                @APIDocument(
                    title: "Update post",
                    description: "Partially update a post",
                    tags: ["Posts"]
                )
                struct UpdatePostRequest {
                }
                """,
                expandedSource: """
                struct UpdatePostRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .patch
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "UpdatePostRequest",
                            title: "Update post",
                            description: "Partially update a post",
                            method: "PATCH",
                            path: "/posts/{id}",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension UpdatePostRequest: APIRequest {
                }

                extension UpdatePostRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }
        
        @Test("@APIDocument - DELETE 메서드는 대문자로 생성")
        func apiDocumentDeleteMethodUppercase() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: EmptyResponse.self,
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .delete
                )
                @APIDocument(
                    title: "Delete post",
                    description: "Delete a post by ID",
                    tags: ["Posts"]
                )
                struct DeletePostRequest {
                }
                """,
                expandedSource: """
                struct DeletePostRequest {

                    typealias Response = EmptyResponse

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .delete
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "DeletePostRequest",
                            title: "Delete post",
                            description: "Delete a post by ID",
                            method: "DELETE",
                            path: "/posts/{id}",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: [],
                            responseTypeName: "EmptyResponse"
                        )
                    }
                }

                extension DeletePostRequest: APIRequest {
                }

                extension DeletePostRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }
        
        @Test("@APIDocument - PUT 메서드는 대문자로 생성")
        func apiDocumentPutMethodUppercase() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.example.com",
                    path: "/posts/{id}",
                    method: .put
                )
                @APIDocument(
                    title: "Replace post",
                    description: "Replace a post completely",
                    tags: ["Posts"]
                )
                struct ReplacePostRequest {
                }
                """,
                expandedSource: """
                struct ReplacePostRequest {

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.example.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .put
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "ReplacePostRequest",
                            title: "Replace post",
                            description: "Replace a post completely",
                            method: "PUT",
                            path: "/posts/{id}",
                            baseURLString: "https://api.example.com",
                            headers: [:],
                            tags: ["Posts"],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension ReplacePostRequest: APIRequest {
                }

                extension ReplacePostRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }

        // MARK: - Special Characters Integration Tests

        @Test("@APIDocument with special characters in all fields")
        func apiDocumentWithSpecialCharactersIntegration() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: PostDTO.self,
                    baseURL: "https://api.test.com",
                    path: "/posts/{id}",
                    method: .get
                )
                @APIDocument(
                    title: "Get \\"specific\\" post",
                    description: "Retrieve post\\nwith special\\tchars",
                    tags: ["Posts\\\\Category", "Read\\"Only"]
                )
                struct GetPostRequest {
                    @PathParameter
                    var id: String
                    
                    @QueryParameter
                    var filter: String?
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                    @PathParameter
                    var id: String
                    
                    @QueryParameter
                    var filter: String?

                    typealias Response = PostDTO

                    var baseURLString: String {
                        "https://api.test.com"
                    }

                    var path: String {
                        "/posts/{id}"
                    }

                    var method: HTTPMethod {
                        .get
                    }

                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostRequest",
                            title: "",
                            description: "",
                            method: "GET",
                            path: "/posts/{id}",
                            baseURLString: "https://api.test.com",
                            headers: [:],
                            tags: [],
                            parameters: [],
                            responseTypeName: "PostDTO"
                        )
                    }

                    /// 엔드포인트 메타데이터
                    public static var metadata: EndpointMetadata {
                        EndpointMetadata(
                            id: "GetPostRequest",
                            title: "Get \\"specific\\" post",
                            description: "Retrieve post\\nwith special\\tchars",
                            method: "GET",
                            path: "/posts/{id}",
                            baseURLString: "https://api.test.com",
                            headers: [:],
                            tags: ["Posts\\\\Category", "Read\\"Only"],
                            parameters: ["id", "filter"],
                            responseTypeName: "PostDTO"
                        )
                    }
                }

                extension GetPostRequest: APIRequest {
                }

                extension GetPostRequest: DocumentableAPIRequest {
                }
                """,
                macros: testMacros
            )
        }
    }

    // Stub for QueryParameter (테스트용)
    struct QueryParameterMacroStub: MemberMacro {
        static func expansion(
            of _: SwiftSyntax.AttributeSyntax,
            providingMembersOf _: some SwiftSyntax.DeclGroupSyntax,
            conformingTo _: [SwiftSyntax.TypeSyntax],
            in _: some SwiftSyntaxMacros.MacroExpansionContext
        ) throws -> [SwiftSyntax.DeclSyntax] {
            []
        }
    }

#endif // os(macOS)

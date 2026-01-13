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
                            method: "get",
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

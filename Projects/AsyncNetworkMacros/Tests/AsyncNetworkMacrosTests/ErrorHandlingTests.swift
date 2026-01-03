//
//  ErrorHandlingTests.swift
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

    // MARK: - ErrorHandlingTests

    @Suite("APIRequest Macro - Error Handling Tests")
    struct ErrorHandlingTests {
        let testMacros: [String: Macro.Type] = [
            "APIRequest": APIRequestMacroImpl.self
        ]

        @Test("class에 적용 시 에러")
        func classError() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get a post",
                    path: "/posts/1",
                    method: .get
                )
                class GetPostRequest {
                }
                """,
                expandedSource: """
                class GetPostRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@APIRequest can only be applied to a struct",
                        line: 1,
                        column: 1
                    )
                ],
                macros: testMacros
            )
        }

        @Test("enum에 적용 시 에러")
        func enumError() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get a post",
                    path: "/posts/1",
                    method: .get
                )
                enum GetPostRequest {
                    case test
                }
                """,
                expandedSource: """
                enum GetPostRequest {
                    case test
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@APIRequest can only be applied to a struct",
                        line: 1,
                        column: 1
                    )
                ],
                macros: testMacros
            )
        }

        @Test("필수 파라미터 누락 시 에러 - response")
        func missingResponseError() {
            assertMacroExpansion(
                """
                @APIRequest(
                    title: "Get a post",
                    path: "/posts/1",
                    method: .get
                )
                struct GetPostRequest {
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@APIRequest missing required argument: response",
                        line: 1,
                        column: 1
                    )
                ],
                macros: testMacros
            )
        }

        @Test("필수 파라미터 누락 시 에러 - baseURL")
        func missingBaseURLError() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    path: "/posts/1",
                    method: .get
                )
                struct GetPostRequest {
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@APIRequest missing required argument: baseURL",
                        line: 1,
                        column: 1
                    )
                ],
                macros: testMacros
            )
        }

        @Test("필수 파라미터 누락 시 에러 - path")
        func missingPathError() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get a post",
                    method: .get
                )
                struct GetPostRequest {
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@APIRequest missing required argument: path",
                        line: 1,
                        column: 1
                    )
                ],
                macros: testMacros
            )
        }

        @Test("필수 파라미터 누락 시 에러 - method")
        func missingMethodError() {
            assertMacroExpansion(
                """
                @APIRequest(
                    response: Post.self,
                    title: "Get a post",
                    path: "/posts/1"
                )
                struct GetPostRequest {
                }
                """,
                expandedSource: """
                struct GetPostRequest {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@APIRequest missing required argument: method",
                        line: 1,
                        column: 1
                    )
                ],
                macros: testMacros
            )
        }
    }

#endif // os(macOS)


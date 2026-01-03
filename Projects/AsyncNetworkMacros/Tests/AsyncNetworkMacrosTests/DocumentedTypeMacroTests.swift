//
//  DocumentedTypeMacroTests.swift
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

    // MARK: - DocumentedTypeMacroTests

    @Suite("DocumentedType Macro Tests")
    struct DocumentedTypeMacroTests {
        let testMacros: [String: Macro.Type] = [
            "DocumentedType": DocumentedTypeMacroImpl.self,
        ]

        @Test("struct에 적용 - 기본 프로퍼티")
        func basicStruct() {
            assertMacroExpansion(
                """
                @DocumentedType
                struct User {
                    let id: Int
                    let name: String
                    let email: String
                }
                """,
                expandedSource: """
                struct User {
                    let id: Int
                    let name: String
                    let email: String

                    public static var typeStructure: String {
                        _ = _register  // 등록 강제 실행
                        return "struct User {\\n    let id: Int\\n    let name: String\\n    let email: String\\n}"
                    }

                    public static var relatedTypeNames: [String] {
                        _ = _register  // 등록 강제 실행
                        return []
                    }

                    private static let _register: Void = {
                        TypeRegistry.shared.register(User.self)
                    }()
                }

                extension User: TypeStructureProvider {
                }
                """,
                macros: testMacros
            )
        }

        @Test("struct에 적용 - 다양한 프로퍼티 타입")
        func structWithVariousTypes() {
            assertMacroExpansion(
                """
                @DocumentedType
                struct Post {
                    let id: Int
                    let title: String
                    let isPublished: Bool
                    let rating: Double
                    var viewCount: Int
                }
                """,
                expandedSource: """
                struct Post {
                    let id: Int
                    let title: String
                    let isPublished: Bool
                    let rating: Double
                    var viewCount: Int

                    public static var typeStructure: String {
                        _ = _register  // 등록 강제 실행
                        return "struct Post {\\n    let id: Int\\n    let title: String\\n    let isPublished: Bool\\n    let rating: Double\\n    var viewCount: Int\\n}"
                    }

                    public static var relatedTypeNames: [String] {
                        _ = _register  // 등록 강제 실행
                        return []
                    }

                    private static let _register: Void = {
                        TypeRegistry.shared.register(Post.self)
                    }()
                }

                extension Post: TypeStructureProvider {
                }
                """,
                macros: testMacros
            )
        }

        @Test("struct에 적용 - 중첩 커스텀 타입")
        func structWithNestedTypes() {
            assertMacroExpansion(
                """
                @DocumentedType
                struct Article {
                    let id: Int
                    let author: User
                    let comments: [Comment]
                }
                """,
                expandedSource: """
                struct Article {
                    let id: Int
                    let author: User
                    let comments: [Comment]

                    public static var typeStructure: String {
                        _ = _register  // 등록 강제 실행
                        return "struct Article {\\n    let id: Int\\n    let author: User\\n    let comments: [Comment]\\n}"
                    }

                    public static var relatedTypeNames: [String] {
                        _ = _register  // 등록 강제 실행
                        return ["Comment", "User"]
                    }

                    private static let _register: Void = {
                        TypeRegistry.shared.register(Article.self)
                    }()
                }

                extension Article: TypeStructureProvider {
                }
                """,
                macros: testMacros
            )
        }

        @Test("struct에 적용 - 옵셔널 타입")
        func structWithOptionals() {
            assertMacroExpansion(
                """
                @DocumentedType
                struct Profile {
                    let userId: Int
                    let bio: String?
                    let avatar: URL?
                }
                """,
                expandedSource: """
                struct Profile {
                    let userId: Int
                    let bio: String?
                    let avatar: URL?

                    public static var typeStructure: String {
                        _ = _register  // 등록 강제 실행
                        return "struct Profile {\\n    let userId: Int\\n    let bio: String?\\n    let avatar: URL?\\n}"
                    }

                    public static var relatedTypeNames: [String] {
                        _ = _register  // 등록 강제 실행
                        return []
                    }

                    private static let _register: Void = {
                        TypeRegistry.shared.register(Profile.self)
                    }()
                }

                extension Profile: TypeStructureProvider {
                }
                """,
                macros: testMacros
            )
        }

        @Test("struct에 적용 - 옵셔널 커스텀 타입")
        func structWithOptionalCustomTypes() {
            assertMacroExpansion(
                """
                @DocumentedType
                struct Order {
                    let id: Int
                    let customer: Customer?
                    let items: [Product]?
                }
                """,
                expandedSource: """
                struct Order {
                    let id: Int
                    let customer: Customer?
                    let items: [Product]?

                    public static var typeStructure: String {
                        _ = _register  // 등록 강제 실행
                        return "struct Order {\\n    let id: Int\\n    let customer: Customer?\\n    let items: [Product]?\\n}"
                    }

                    public static var relatedTypeNames: [String] {
                        _ = _register  // 등록 강제 실행
                        return ["Customer", "Product"]
                    }

                    private static let _register: Void = {
                        TypeRegistry.shared.register(Order.self)
                    }()
                }

                extension Order: TypeStructureProvider {
                }
                """,
                macros: testMacros
            )
        }

        @Test("struct에 적용 - 계산 프로퍼티 제외")
        func structWithComputedProperties() {
            assertMacroExpansion(
                """
                @DocumentedType
                struct Rectangle {
                    let width: Double
                    let height: Double
                    
                    var area: Double {
                        width * height
                    }
                }
                """,
                expandedSource: """
                struct Rectangle {
                    let width: Double
                    let height: Double
                    
                    var area: Double {
                        width * height
                    }

                    public static var typeStructure: String {
                        _ = _register  // 등록 강제 실행
                        return "struct Rectangle {\\n    let width: Double\\n    let height: Double\\n}"
                    }

                    public static var relatedTypeNames: [String] {
                        _ = _register  // 등록 강제 실행
                        return []
                    }

                    private static let _register: Void = {
                        TypeRegistry.shared.register(Rectangle.self)
                    }()
                }

                extension Rectangle: TypeStructureProvider {
                }
                """,
                macros: testMacros
            )
        }

        @Test("struct에 적용 - 빈 struct")
        func emptyStruct() {
            assertMacroExpansion(
                """
                @DocumentedType
                struct EmptyResponse {
                }
                """,
                expandedSource: """
                struct EmptyResponse {

                    public static var typeStructure: String {
                        _ = _register  // 등록 강제 실행
                        return "struct EmptyResponse {\\n\\n}"
                    }

                    public static var relatedTypeNames: [String] {
                        _ = _register  // 등록 강제 실행
                        return []
                    }

                    private static let _register: Void = {
                        TypeRegistry.shared.register(EmptyResponse.self)
                    }()
                }

                extension EmptyResponse: TypeStructureProvider {
                }
                """,
                macros: testMacros
            )
        }

        @Test("class에 적용")
        func basicClass() {
            assertMacroExpansion(
                """
                @DocumentedType
                class Vehicle {
                    let brand: String
                    var model: String
                    let year: Int
                }
                """,
                expandedSource: """
                class Vehicle {
                    let brand: String
                    var model: String
                    let year: Int

                    public static var typeStructure: String {
                        _ = _register  // 등록 강제 실행
                        return "class Vehicle {\\n    let brand: String\\n    var model: String\\n    let year: Int\\n}"
                    }

                    public static var relatedTypeNames: [String] {
                        _ = _register  // 등록 강제 실행
                        return []
                    }

                    private static let _register: Void = {
                        TypeRegistry.shared.register(Vehicle.self)
                    }()
                }

                extension Vehicle: TypeStructureProvider {
                }
                """,
                macros: testMacros
            )
        }

        @Test("class에 적용 - 중첩 타입")
        func classWithNestedTypes() {
            assertMacroExpansion(
                """
                @DocumentedType
                class Company {
                    let name: String
                    var ceo: Person
                    let employees: [Person]
                }
                """,
                expandedSource: """
                class Company {
                    let name: String
                    var ceo: Person
                    let employees: [Person]

                    public static var typeStructure: String {
                        _ = _register  // 등록 강제 실행
                        return "class Company {\\n    let name: String\\n    var ceo: Person\\n    let employees: [Person]\\n}"
                    }

                    public static var relatedTypeNames: [String] {
                        _ = _register  // 등록 강제 실행
                        return ["Person"]
                    }

                    private static let _register: Void = {
                        TypeRegistry.shared.register(Company.self)
                    }()
                }

                extension Company: TypeStructureProvider {
                }
                """,
                macros: testMacros
            )
        }

        @Test("enum에 적용 시 에러")
        func enumError() {
            assertMacroExpansion(
                """
                @DocumentedType
                enum Status {
                    case active
                    case inactive
                }
                """,
                expandedSource: """
                enum Status {
                    case active
                    case inactive
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@DocumentedType can only be applied to a struct or class",
                        line: 1,
                        column: 1
                    ),
                ],
                macros: testMacros
            )
        }

        @Test("프리미티브 타입만 있는 경우")
        func structWithOnlyPrimitives() {
            assertMacroExpansion(
                """
                @DocumentedType
                struct Config {
                    let apiKey: String
                    let timeout: Int
                    let retryCount: Int
                    let isEnabled: Bool
                    let baseURL: URL
                }
                """,
                expandedSource: """
                struct Config {
                    let apiKey: String
                    let timeout: Int
                    let retryCount: Int
                    let isEnabled: Bool
                    let baseURL: URL

                    public static var typeStructure: String {
                        _ = _register  // 등록 강제 실행
                        return "struct Config {\\n    let apiKey: String\\n    let timeout: Int\\n    let retryCount: Int\\n    let isEnabled: Bool\\n    let baseURL: URL\\n}"
                    }

                    public static var relatedTypeNames: [String] {
                        _ = _register  // 등록 강제 실행
                        return []
                    }

                    private static let _register: Void = {
                        TypeRegistry.shared.register(Config.self)
                    }()
                }

                extension Config: TypeStructureProvider {
                }
                """,
                macros: testMacros
            )
        }

        @Test("복잡한 중첩 타입 처리")
        func structWithComplexNestedTypes() {
            assertMacroExpansion(
                """
                @DocumentedType
                struct BlogPost {
                    let id: Int
                    let title: String
                    let author: User
                    let tags: [Tag]
                    let comments: [Comment]?
                    let metadata: PostMetadata
                }
                """,
                expandedSource: """
                struct BlogPost {
                    let id: Int
                    let title: String
                    let author: User
                    let tags: [Tag]
                    let comments: [Comment]?
                    let metadata: PostMetadata

                    public static var typeStructure: String {
                        _ = _register  // 등록 강제 실행
                        return "struct BlogPost {\\n    let id: Int\\n    let title: String\\n    let author: User\\n    let tags: [Tag]\\n    let comments: [Comment]?\\n    let metadata: PostMetadata\\n}"
                    }

                    public static var relatedTypeNames: [String] {
                        _ = _register  // 등록 강제 실행
                        return ["Comment", "PostMetadata", "Tag", "User"]
                    }

                    private static let _register: Void = {
                        TypeRegistry.shared.register(BlogPost.self)
                    }()
                }

                extension BlogPost: TypeStructureProvider {
                }
                """,
                macros: testMacros
            )
        }
    }

#endif // os(macOS)

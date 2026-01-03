//
//  TypeRegistryTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/04.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - TypeRegistryTests

struct TypeRegistryTests {
    // MARK: - Test Types

    private struct TestUser: Codable, Sendable, TypeStructureProvider {
        let id: Int
        let name: String
        let email: String?

        static var typeStructure: String {
            """
            struct TestUser {
                let id: Int
                let name: String
                let email: String?
            }
            """
        }

        static var relatedTypeNames: [String] { [] }
    }

    private struct TestPost: Codable, Sendable, TypeStructureProvider {
        let title: String
        let content: String

        static var typeStructure: String {
            """
            struct TestPost {
                let title: String
                let content: String
            }
            """
        }

        static var relatedTypeNames: [String] { [] }
    }

    // MARK: - Registration Tests

    @Test("TypeRegistry - 타입 등록")
    func registerType() {
        // Given
        let registry = TypeRegistry.shared

        // When
        registry.register(TestUser.self)
        let retrievedType = registry.type(forName: "TestUser")

        // Then
        #expect(retrievedType != nil)
    }

    @Test("TypeRegistry - 여러 타입 등록")
    func registerMultipleTypes() {
        // Given
        let registry = TypeRegistry.shared

        // When
        registry.register(TestUser.self)
        registry.register(TestPost.self)

        let userType = registry.type(forName: "TestUser")
        let postType = registry.type(forName: "TestPost")

        // Then
        #expect(userType != nil)
        #expect(postType != nil)
    }

    @Test("TypeRegistry - 등록되지 않은 타입 조회")
    func getNonExistentType() {
        // Given
        let registry = TypeRegistry.shared

        // When
        let type = registry.type(forName: "NonExistentType")

        // Then
        #expect(type == nil)
    }

    @Test("TypeRegistry - 모든 타입 이름 조회")
    func getAllTypeNames() {
        // Given
        let registry = TypeRegistry.shared
        registry.register(TestUser.self)
        registry.register(TestPost.self)

        // When
        let allNames = registry.allTypeNames()

        // Then
        #expect(allNames.contains("TestUser"))
        #expect(allNames.contains("TestPost"))
    }

    @Test("TypeStructureProvider - typeStructure 프로퍼티")
    func typeStructureMethod() {
        // Given & When
        let structure = TestUser.typeStructure

        // Then
        #expect(structure.contains("struct TestUser"))
        #expect(structure.contains("let id: Int"))
        #expect(structure.contains("let name: String"))
        #expect(structure.contains("let email: String?"))
    }
}

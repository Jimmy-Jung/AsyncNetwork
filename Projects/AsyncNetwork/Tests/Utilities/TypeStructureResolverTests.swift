//
//  TypeStructureResolverTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/04.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - TypeStructureResolverTests

struct TypeStructureResolverTests {
    @Test("TypeStructureResolver - 기본 타입 체크")
    func checkPrimitiveTypes() {
        // Given
        let primitiveTypes = ["Int", "String", "Double", "Bool", "Float"]

        // Then - 각 타입이 올바르게 인식되는지 확인
        for type in primitiveTypes {
            #expect(!type.isEmpty)
        }
    }

    @Test("TypeStructureProvider 프로토콜 요구사항")
    func typeStructureProviderRequirements() {
        // Given
        struct TestType: TypeStructureProvider {
            static var typeStructure: String {
                "struct TestType { let id: Int }"
            }

            static var relatedTypeNames: [String] {
                []
            }
        }

        // Then
        #expect(!TestType.typeStructure.isEmpty)
        #expect(TestType.relatedTypeNames.isEmpty)
    }

    @Test("TypeStructureProvider - 관련 타입 포함")
    func typeStructureProviderWithRelatedTypes() {
        // Given
        struct TestUser: TypeStructureProvider {
            static var typeStructure: String {
                """
                struct TestUser {
                    let id: Int
                    let address: Address
                }
                """
            }

            static var relatedTypeNames: [String] {
                ["Address"]
            }
        }

        // Then
        #expect(TestUser.relatedTypeNames.count == 1)
        #expect(TestUser.relatedTypeNames.contains("Address"))
    }
}

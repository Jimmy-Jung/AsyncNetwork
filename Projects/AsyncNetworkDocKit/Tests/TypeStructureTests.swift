//
//  TypeStructureTests.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/04.
//

@testable import AsyncNetworkDocKit
import Foundation
import Testing

// MARK: - TypeStructureTests

struct TypeStructureViewModelTests {
    @Test("TypeStructure - 기본 생성")
    func createBasicStructure() {
        // Given
        let properties = [
            TypeProperty(name: "id", type: "Int"),
            TypeProperty(name: "name", type: "String")
        ]

        // When
        let structure = TypeStructure(name: "User", properties: properties)

        // Then
        #expect(structure.name == "User")
        #expect(structure.id == "User")
        #expect(structure.properties.count == 2)
    }

    @Test("TypeProperty - 필수 프로퍼티")
    func createRequiredProperty() {
        // Given & When
        let property = TypeProperty(name: "id", type: "Int", isOptional: false)

        // Then
        #expect(property.name == "id")
        #expect(property.type == "Int")
        #expect(property.isOptional == false)
        #expect(property.isArray == false)
        #expect(property.displayType == "Int")
    }

    @Test("TypeProperty - 옵셔널 프로퍼티")
    func createOptionalProperty() {
        // Given & When
        let property = TypeProperty(name: "email", type: "String", isOptional: true)

        // Then
        #expect(property.name == "email")
        #expect(property.type == "String")
        #expect(property.isOptional == true)
        #expect(property.displayType == "String?")
    }

    @Test("TypeProperty - 배열 프로퍼티")
    func createArrayProperty() {
        // Given & When
        let property = TypeProperty(name: "tags", type: "String", isArray: true)

        // Then
        #expect(property.name == "tags")
        #expect(property.type == "String")
        #expect(property.isArray == true)
        #expect(property.displayType == "[String]")
    }

    @Test("TypeProperty - 옵셔널 배열 프로퍼티")
    func createOptionalArrayProperty() {
        // Given & When
        let property = TypeProperty(name: "tags", type: "String", isOptional: true, isArray: true)

        // Then
        #expect(property.name == "tags")
        #expect(property.isOptional == true)
        #expect(property.isArray == true)
        #expect(property.displayType == "[String]?")
    }

    @Test("TypeProperty - 중첩 타입")
    func createNestedTypeProperty() {
        // Given & When
        let property = TypeProperty(name: "address", type: "Address", nestedTypeName: "Address")

        // Then
        #expect(property.name == "address")
        #expect(property.type == "Address")
        #expect(property.nestedTypeName == "Address")
    }

    @Test("TypeStructureParser - struct 파싱")
    func parseStructText() {
        // Given
        let structText = """
        struct User {
            let id: Int
            let name: String
            let email: String?
        }
        """

        // When
        let parsed = TypeStructureParser.parse(structText)

        // Then
        #expect(parsed != nil)
        #expect(parsed?.name == "User")
        #expect(parsed?.properties.count == 3)
    }

    @Test("TypeStructureParser - 프로퍼티 파싱")
    func parsePropertyTypes() {
        // Given
        let structText = """
        struct Response {
            let count: Int
            let items: [Item]
            let total: Double?
        }
        """

        // When
        let parsed = TypeStructureParser.parse(structText)

        // Then
        let properties = parsed?.properties ?? []
        #expect(properties.count == 3)

        let countProp = properties.first(where: { $0.name == "count" })
        #expect(countProp?.type == "Int")
        #expect(countProp?.isOptional == false)

        let itemsProp = properties.first(where: { $0.name == "items" })
        #expect(itemsProp?.type == "Item")
        #expect(itemsProp?.isArray == true)

        let totalProp = properties.first(where: { $0.name == "total" })
        #expect(totalProp?.type == "Double")
        #expect(totalProp?.isOptional == true)
    }

    @Test("TypeStructureParser - 잘못된 형식")
    func parseInvalidFormat() {
        // Given
        let invalidText = "This is not a struct"

        // When
        let parsed = TypeStructureParser.parse(invalidText)

        // Then
        #expect(parsed == nil)
    }

    @Test("TypeStructureParser - 빈 struct")
    func parseEmptyStruct() {
        // Given
        let emptyStruct = """
        struct Empty {
        }
        """

        // When
        let parsed = TypeStructureParser.parse(emptyStruct)

        // Then
        #expect(parsed != nil)
        #expect(parsed?.name == "Empty")
        #expect(parsed?.properties.isEmpty == true)
    }
}

//
//  EndpointMetadataTests.swift
//  AsyncNetwork
//
//  Created by jimmy on 2026/01/04.
//

@testable import AsyncNetworkCore
import Foundation
import Testing

// MARK: - EndpointMetadataTests

struct EndpointMetadataTests {
    @Test("EndpointMetadata 생성 및 속성 확인")
    func createMetadata() {
        // Given & When
        let metadata = EndpointMetadata(
            id: "test-id",
            title: "Test Endpoint",
            description: "Test Description",
            method: "GET",
            path: "/test",
            baseURLString: "https://api.example.com",
            headers: ["Content-Type": "application/json"],
            tags: ["test", "api"],
            parameters: [],
            requestBodyExample: nil,
            responseExample: "{\"success\": true}",
            responseTypeName: "Response"
        )

        // Then
        #expect(metadata.id == "test-id")
        #expect(metadata.title == "Test Endpoint")
        #expect(metadata.description == "Test Description")
        #expect(metadata.method == "GET")
        #expect(metadata.path == "/test")
        #expect(metadata.baseURLString == "https://api.example.com")
        #expect(metadata.headers?.count == 1)
        #expect(metadata.tags.count == 2)
        #expect(metadata.responseTypeName == "Response")
    }

    @Test("ParameterInfo 생성")
    func createParameterInfo() {
        // Given & When
        let param = ParameterInfo(
            id: "param-1",
            name: "userId",
            type: "String",
            location: .path,
            isRequired: true,
            description: "User ID",
            defaultValue: nil,
            exampleValue: "123"
        )

        // Then
        #expect(param.name == "userId")
        #expect(param.type == "String")
        #expect(param.location == .path)
        #expect(param.isRequired == true)
        #expect(param.exampleValue == "123")
    }

    @Test("ParameterLocation 모든 케이스")
    func parameterLocations() {
        // Given
        let locations: [ParameterLocation] = [.query, .path, .header, .body]

        // Then
        #expect(locations.count == 4)
        #expect(locations.contains(.query))
        #expect(locations.contains(.path))
        #expect(locations.contains(.header))
        #expect(locations.contains(.body))
    }

    @Test("RequestBodyFieldInfo 생성")
    func createRequestBodyField() {
        // Given & When
        let field = RequestBodyFieldInfo(
            name: "email",
            type: "String",
            isRequired: true,
            exampleValue: "test@example.com",
            fieldKind: .primitive
        )

        // Then
        #expect(field.name == "email")
        #expect(field.type == "String")
        #expect(field.isRequired == true)
        #expect(field.exampleValue == "test@example.com")
        #expect(field.fieldKind == .primitive)
    }

    @Test("RequestBodyFieldInfo.FieldKind 모든 케이스")
    func fieldKinds() {
        // Given
        let kinds: [RequestBodyFieldInfo.FieldKind] = [.primitive, .array, .object]

        // Then
        #expect(kinds.count == 3)
        #expect(kinds.contains(.primitive))
        #expect(kinds.contains(.array))
        #expect(kinds.contains(.object))
    }
}

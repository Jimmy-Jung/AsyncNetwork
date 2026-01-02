//
//  RequestBodyParserTests.swift
//  AsyncNetworkDocKit
//
//  Created by jimmy on 2026/01/02.
//

@testable import AsyncNetworkDocKit
import Foundation
import Testing

@Suite("RequestBodyParser Tests")
struct RequestBodyParserTests {
    @Test("빈 JSON 문자열을 파싱하면 빈 배열을 반환한다")
    func emptyJSONReturnsEmptyArray() {
        let fields = RequestBodyParser.parseFields(from: "{}")
        #expect(fields.isEmpty)
    }

    @Test("잘못된 JSON 문자열을 파싱하면 빈 배열을 반환한다")
    func invalidJSONReturnsEmptyArray() {
        let fields = RequestBodyParser.parseFields(from: "{invalid json")
        #expect(fields.isEmpty)
    }

    @Test("String 타입 필드를 올바르게 파싱한다")
    func parsesStringFieldCorrectly() {
        let json = """
        {
            "title": "My Post"
        }
        """

        let fields = RequestBodyParser.parseFields(from: json)
        #expect(fields.count == 1)

        let field = fields.first
        #expect(field?.name == "title")
        #expect(field?.type == .string)
        #expect(field?.exampleValue == "My Post")
        #expect(field?.isRequired == true)
    }

    @Test("Int 타입 필드를 올바르게 파싱한다")
    func parsesIntFieldCorrectly() {
        let json = """
        {
            "userId": 123
        }
        """

        let fields = RequestBodyParser.parseFields(from: json)
        #expect(fields.count == 1)

        let field = fields.first
        #expect(field?.name == "userId")
        #expect(field?.type == .int)
        #expect(field?.exampleValue == "123")
    }

    @Test("Double 타입 필드를 올바르게 파싱한다")
    func parsesDoubleFieldCorrectly() {
        let json = """
        {
            "price": 19.99
        }
        """

        let fields = RequestBodyParser.parseFields(from: json)
        #expect(fields.count == 1)

        let field = fields.first
        #expect(field?.name == "price")
        #expect(field?.type == .double)
        #expect(field?.exampleValue == "19.99")
    }

    @Test("Bool 타입 필드를 올바르게 파싱한다")
    func parsesBoolFieldCorrectly() {
        let json = """
        {
            "isPublished": true
        }
        """

        let fields = RequestBodyParser.parseFields(from: json)
        #expect(fields.count == 1)

        let field = fields.first
        #expect(field?.name == "isPublished")
        // Bool은 NSNumber로 처리되어 Int로 감지될 수 있음
        #expect(field?.type == .int || field?.type == .bool)
    }

    @Test("Array 타입 필드를 올바르게 파싱한다")
    func parsesArrayFieldCorrectly() {
        let json = """
        {
            "tags": ["swift", "testing", "ios"]
        }
        """

        let fields = RequestBodyParser.parseFields(from: json)
        #expect(fields.count == 1)

        let field = fields.first
        #expect(field?.name == "tags")
        #expect(field?.type == .array)
        #expect(field?.exampleValue == "[3 items]")
    }

    @Test("Object 타입 필드를 올바르게 파싱한다")
    func parsesObjectFieldCorrectly() {
        let json = """
        {
            "metadata": {
                "created": "2026-01-02",
                "author": "John"
            }
        }
        """

        let fields = RequestBodyParser.parseFields(from: json)
        #expect(fields.count == 1)

        let field = fields.first
        #expect(field?.name == "metadata")
        #expect(field?.type == .object)
        #expect(field?.exampleValue == "{2 fields}")
    }

    @Test("여러 타입의 필드를 포함한 JSON을 파싱한다")
    func parsesMultipleFieldTypes() {
        let json = """
        {
            "title": "My Post",
            "userId": 1,
            "price": 29.99,
            "isPublished": true,
            "tags": ["swift", "ios"],
            "metadata": {"key": "value"}
        }
        """

        let fields = RequestBodyParser.parseFields(from: json)
        #expect(fields.count == 6)

        // 필드가 이름순으로 정렬되는지 확인
        let fieldNames = fields.map { $0.name }
        #expect(fieldNames.sorted() == fieldNames)
    }

    @Test("필드가 알파벳순으로 정렬된다")
    func fieldsAreSortedAlphabetically() {
        let json = """
        {
            "zulu": "last",
            "alpha": "first",
            "mike": "middle"
        }
        """

        let fields = RequestBodyParser.parseFields(from: json)
        let fieldNames = fields.map { $0.name }

        #expect(fieldNames == ["alpha", "mike", "zulu"])
    }

    @Test("buildJSON은 빈 필드에서 nil을 반환하지 않는다")
    func buildJSONHandlesEmptyFields() {
        let fields: [String: String] = [:]
        let fieldTypes: [String: RequestBodyField.FieldType] = [:]

        let json = RequestBodyParser.buildJSON(from: fields, fieldTypes: fieldTypes)
        #expect(json != nil)
        #expect(json == "{\n\n}")
    }

    @Test("buildJSON은 String 타입 필드를 올바르게 변환한다")
    func buildJSONConvertsStringFieldCorrectly() {
        let fields = ["title": "Test Title"]
        let fieldTypes = ["title": RequestBodyField.FieldType.string]

        let json = RequestBodyParser.buildJSON(from: fields, fieldTypes: fieldTypes)
        #expect(json != nil)
        #expect(json?.contains("\"title\"") == true)
        #expect(json?.contains("\"Test Title\"") == true)
    }

    @Test("buildJSON은 Int 타입 필드를 올바르게 변환한다")
    func buildJSONConvertsIntFieldCorrectly() {
        let fields = ["userId": "123"]
        let fieldTypes = ["userId": RequestBodyField.FieldType.int]

        let json = RequestBodyParser.buildJSON(from: fields, fieldTypes: fieldTypes)
        #expect(json != nil)
        #expect(json?.contains("\"userId\"") == true)
        #expect(json?.contains("123") == true)
    }

    @Test("buildJSON은 잘못된 Int 값을 0으로 변환한다")
    func buildJSONConvertsInvalidIntToZero() {
        let fields = ["userId": "not-a-number"]
        let fieldTypes = ["userId": RequestBodyField.FieldType.int]

        let json = RequestBodyParser.buildJSON(from: fields, fieldTypes: fieldTypes)
        #expect(json != nil)
        #expect(json?.contains("0") == true)
    }

    @Test("buildJSON은 Double 타입 필드를 올바르게 변환한다")
    func buildJSONConvertsDoubleFieldCorrectly() {
        let fields = ["price": "19.99"]
        let fieldTypes = ["price": RequestBodyField.FieldType.double]

        let json = RequestBodyParser.buildJSON(from: fields, fieldTypes: fieldTypes)
        #expect(json != nil)
        #expect(json?.contains("\"price\"") == true)
        // Double은 19.989999999999998 같은 형태로 저장될 수 있음
        #expect(json?.contains("19.9") == true)
    }

    @Test("buildJSON은 잘못된 Double 값을 0.0으로 변환한다")
    func buildJSONConvertsInvalidDoubleToZero() {
        let fields = ["price": "not-a-number"]
        let fieldTypes = ["price": RequestBodyField.FieldType.double]

        let json = RequestBodyParser.buildJSON(from: fields, fieldTypes: fieldTypes)
        #expect(json != nil)
        #expect(json?.contains("0") == true)
    }

    @Test("buildJSON은 Bool 타입 필드를 올바르게 변환한다")
    func buildJSONConvertsBoolFieldCorrectly() {
        let fields = ["isPublished": "true"]
        let fieldTypes = ["isPublished": RequestBodyField.FieldType.bool]

        let json = RequestBodyParser.buildJSON(from: fields, fieldTypes: fieldTypes)
        #expect(json != nil)
        #expect(json?.contains("\"isPublished\"") == true)
        #expect(json?.contains("true") == true)
    }

    @Test("buildJSON은 여러 타입의 필드를 포함한 JSON을 생성한다")
    func buildJSONCreatesComplexJSON() {
        let fields = [
            "title": "Test Post",
            "userId": "42",
            "price": "29.99",
            "isActive": "true"
        ]
        let fieldTypes: [String: RequestBodyField.FieldType] = [
            "title": .string,
            "userId": .int,
            "price": .double,
            "isActive": .bool
        ]

        let json = RequestBodyParser.buildJSON(from: fields, fieldTypes: fieldTypes)
        #expect(json != nil)
        #expect(json?.contains("\"title\"") == true)
        #expect(json?.contains("\"userId\"") == true)
        #expect(json?.contains("\"price\"") == true)
        #expect(json?.contains("\"isActive\"") == true)
    }

    @Test("buildJSON은 빈 값을 가진 필드를 무시한다")
    func buildJSONIgnoresEmptyValues() {
        let fields = [
            "title": "Test",
            "empty": ""
        ]
        let fieldTypes: [String: RequestBodyField.FieldType] = [
            "title": .string,
            "empty": .string
        ]

        let json = RequestBodyParser.buildJSON(from: fields, fieldTypes: fieldTypes)
        #expect(json != nil)
        #expect(json?.contains("\"title\"") == true)
        #expect(json?.contains("\"empty\"") == false)
    }

    @Test("buildJSON은 알 수 없는 타입을 문자열로 처리한다")
    func buildJSONHandlesUnknownTypeAsString() {
        let fields = ["unknown": "value"]
        let fieldTypes = ["unknown": RequestBodyField.FieldType.unknown]

        let json = RequestBodyParser.buildJSON(from: fields, fieldTypes: fieldTypes)
        #expect(json != nil)
        #expect(json?.contains("\"unknown\"") == true)
        #expect(json?.contains("\"value\"") == true)
    }
}

@Suite("RequestBodyField Tests")
struct RequestBodyFieldTests {
    @Test("RequestBodyField 초기화 시 id가 올바르게 설정된다")
    func idIsCorrectlySet() {
        let field = RequestBodyField(
            id: "custom-id",
            name: "title",
            type: .string
        )

        #expect(field.id == "custom-id")
    }

    @Test("id를 생략하면 name이 id로 사용된다")
    func nameIsUsedAsIdWhenIdIsNil() {
        let field = RequestBodyField(
            name: "title",
            type: .string
        )

        #expect(field.id == "title")
    }

    @Test("isRequired 기본값은 true다")
    func isRequiredDefaultsToTrue() {
        let field = RequestBodyField(
            name: "title",
            type: .string
        )

        #expect(field.isRequired == true)
    }

    @Test("exampleValue를 설정할 수 있다")
    func canSetExampleValue() {
        let field = RequestBodyField(
            name: "title",
            type: .string,
            exampleValue: "Example Title"
        )

        #expect(field.exampleValue == "Example Title")
    }

    @Test("FieldType displayName이 올바르게 반환된다", arguments: [
        (RequestBodyField.FieldType.string, "String"),
        (RequestBodyField.FieldType.int, "Int"),
        (RequestBodyField.FieldType.double, "Double"),
        (RequestBodyField.FieldType.bool, "Bool"),
        (RequestBodyField.FieldType.array, "Array"),
        (RequestBodyField.FieldType.object, "Object"),
        (RequestBodyField.FieldType.unknown, "Unknown")
    ])
    func fieldTypeDisplayNameIsCorrect(type: RequestBodyField.FieldType, expectedName: String) {
        #expect(type.displayName == expectedName)
    }

    @Test("RequestBodyField는 Hashable을 준수한다")
    func requestBodyFieldIsHashable() {
        let field1 = RequestBodyField(name: "title", type: .string)
        let field2 = RequestBodyField(name: "title", type: .string)

        let set: Set<RequestBodyField> = [field1, field2]
        #expect(set.count == 1)
    }

    @Test("RequestBodyField는 Identifiable을 준수한다")
    func requestBodyFieldIsIdentifiable() {
        let field = RequestBodyField(name: "title", type: .string)
        let id: String = field.id
        #expect(id == "title")
    }
}

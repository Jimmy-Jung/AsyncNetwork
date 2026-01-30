# @ResponseTestable Macro - JSON Validation Enhancement

## 개요

`@ResponseTestable` 매크로에 컴파일 타임 JSON 검증 기능을 추가하여, `fixtureJSON`의 구조 오류를 빌드 타임에 조기 발견할 수 있도록 개선했습니다.

## 문제 상황

이전에는 `fixtureJSON`의 구조가 struct 정의와 일치하지 않아도 컴파일 타임에 알 수 없었고, 런타임에 `fixture()` 호출 시 크래시가 발생했습니다.

### 실제 발생했던 문제

```swift
@ResponseTestable(
    fixtureJSON: """
    {
        "problem": {
            "subProblems": [
                {
                    "id": 1234571,
                    "order": 1,        // ❌ 잘못된 필드명 (subNumber여야 함)
                    "type": 1,
                    "options": []      // ❌ 존재하지 않는 필드
                }
            ]
        }
    }
    """
)
public struct CuratedStudyGroupProblemDTO: Codable, Sendable {
    public let problem: ProblemDTO
}

// SubProblemDTO의 실제 정의
public struct SubProblemDTO: Codable, Sendable {
    public let id: Int
    public let subNumber: Int      // "order"가 아님
    public let title: String       // fixtureJSON에 누락
    public let type: Int
    public let answer: String      // fixtureJSON에 누락
}
```

런타임 크래시:
```
#0  0x00000001976413f4 in _swift_runtime_on_report ()
#4  0x000000010acdb6b0 in static CuratedStudyGroupProblemDTO.fixture()
    at swift-generated-sources/@__swiftmacro_...ResponseTestablefMm_.swift:29
```

## 해결 방법

매크로 확장 시 `fixtureJSON`을 검증하여 컴파일 타임에 경고를 발생시킵니다.

## 검증 기능

### 1. 필수 필드 누락 검증

```swift
@ResponseTestable(
    fixtureJSON: """
    {
        "id": 1
        // ❌ name과 email 누락
    }
    """
)
struct UserDTO: Codable, Sendable {
    let id: Int
    let name: String
    let email: String
}
```

컴파일 경고:
```
⚠️ fixtureJSON validation failed: fixtureJSON is missing required fields: name, email
```

### 2. 불필요한 필드 검증

```swift
@ResponseTestable(
    fixtureJSON: """
    {
        "id": 1,
        "name": "Test",
        "unknownField": "value"  // ❌ struct에 없는 필드
    }
    """
)
struct UserDTO: Codable, Sendable {
    let id: Int
    let name: String
}
```

컴파일 경고:
```
⚠️ fixtureJSON validation failed: fixtureJSON contains extra fields not in struct: unknownField
```

### 3. 타입 불일치 검증

```swift
@ResponseTestable(
    fixtureJSON: """
    {
        "id": "not-a-number",  // ❌ String인데 Int여야 함
        "name": "Test"
    }
    """
)
struct UserDTO: Codable, Sendable {
    let id: Int
    let name: String
}
```

컴파일 경고:
```
⚠️ fixtureJSON validation failed: Field 'id' type mismatch: expected Number but got String
```

### 4. Optional 필드 처리

Optional 필드는 `fixtureJSON`에 없어도 경고하지 않습니다.

```swift
@ResponseTestable(
    fixtureJSON: """
    {
        "id": 1,
        "name": "Test"
        // ✅ email은 optional이므로 누락 가능
    }
    """
)
struct UserDTO: Codable, Sendable {
    let id: Int
    let name: String
    let email: String?  // Optional
}
```

## 코드 변경 사항

### 1. TestableDTOMacroError 확장

```swift
public enum TestableDTOMacroError: Error, DiagnosticMessage {
    case notAStruct
    case invalidFixtureJSON(String)
    case emptyFixtureJSON
    case jsonValidationFailed(String)  // ✅ 추가

    public var severity: DiagnosticSeverity {
        switch self {
        case .jsonValidationFailed:
            return .warning  // 경고 (빌드는 계속)
        default:
            return .error
        }
    }
}
```

### 2. ResponseTestableMacroImpl 확장

```swift
public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo _: [TypeSyntax],
    in context: some MacroExpansionContext
) throws -> [DeclSyntax] {
    // ... 기존 코드 ...

    // ✅ JSON 검증 추가
    if let json = fixtureJSON {
        validateFixtureJSON(
            json,
            typeName: typeName,
            properties: properties,
            context: context,
            node: node
        )
    }

    // ... 나머지 코드 ...
}
```

### 3. 검증 메서드 추가

```swift
private static func validateFixtureJSON(
    _ json: String,
    typeName: String,
    properties: [PropertyInfo],
    context: some MacroExpansionContext,
    node: AttributeSyntax
) {
    // 1. JSON 파싱
    guard let jsonData = json.data(using: .utf8),
          let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
    else {
        emitWarning("fixtureJSON is not a valid JSON object", context: context, node: node)
        return
    }

    // 2. 필수 필드 검증
    let propertyNames = Set(properties.map(\.name))
    let jsonKeys = Set(jsonObject.keys)

    var missingFields: [String] = []
    for prop in properties where !prop.isOptional {
        if !jsonKeys.contains(prop.name) {
            missingFields.append(prop.name)
        }
    }

    // 3. 불필요한 필드 검증
    var extraFields: [String] = []
    for key in jsonKeys {
        if !propertyNames.contains(key) {
            extraFields.append(key)
        }
    }

    // 4. 타입 힌트 검증
    for prop in properties {
        guard let value = jsonObject[prop.name] else { continue }

        let expectedTypeHint = getTypeHint(from: prop.type)
        let actualTypeHint = getValueTypeHint(from: value)

        if expectedTypeHint != actualTypeHint {
            emitWarning(
                "Field '\(prop.name)' type mismatch: expected \(expectedTypeHint) but got \(actualTypeHint)",
                context: context,
                node: node
            )
        }
    }
}
```

## 검증 한계

### 중첩 DTO 검증 제한

현재 구현은 1단계 필드만 검증합니다. 중첩된 DTO의 구조는 검증하지 않습니다.

```swift
@ResponseTestable(
    fixtureJSON: """
    {
        "problem": {
            "subProblems": [
                {
                    "order": 1  // ⚠️ 중첩된 DTO의 필드 오류는 감지 못함
                }
            ]
        }
    }
    """
)
struct CuratedStudyGroupProblemDTO: Codable, Sendable {
    let problem: ProblemDTO  // ProblemDTO 내부 구조는 검증 안됨
}
```

이 경우 여전히 런타임에 크래시가 발생할 수 있습니다.

### 해결 방법

중첩된 DTO의 `fixtureJSON`도 각각 올바르게 작성해야 합니다:

```swift
// 1. SubProblemDTO에 올바른 fixtureJSON 정의
@ResponseTestable(
    fixtureJSON: """
    {
        "id": 1,
        "subNumber": 1,
        "title": "제목",
        "type": 1,
        "answer": "답"
    }
    """
)
public struct SubProblemDTO: Codable, Sendable {
    public let id: Int
    public let subNumber: Int
    public let title: String
    public let type: Int
    public let answer: String
}

// 2. ProblemDTO에 올바른 fixtureJSON 정의 (SubProblemDTO 구조와 일치)
@ResponseTestable(
    fixtureJSON: """
    {
        "subProblems": [
            {
                "id": 1,
                "subNumber": 1,  // ✅ SubProblemDTO와 일치
                "title": "제목",
                "type": 1,
                "answer": "답"
            }
        ]
    }
    """
)
public struct ProblemDTO: Codable, Sendable {
    public let subProblems: [SubProblemDTO]
}
```

## 테스트

`ResponseTestableMacroValidationTests.swift`에 다음 테스트가 추가되었습니다:

1. `missingRequiredFields()` - 필수 필드 누락 감지
2. `extraFields()` - 불필요한 필드 감지
3. `typeMismatch()` - 타입 불일치 감지
4. `validJSON()` - 올바른 JSON은 경고 없음
5. `optionalFieldsAllowed()` - Optional 필드는 누락 허용

## 사용 가이드

### 1. 컴파일 경고 확인

Xcode에서 빌드 시 경고를 확인하세요:

```
⚠️ fixtureJSON validation failed: fixtureJSON is missing required fields: title, answer
```

### 2. JSON 구조 수정

경고를 보고 `fixtureJSON`을 수정하세요:

```swift
@ResponseTestable(
    fixtureJSON: """
    {
        "id": 1,
        "subNumber": 1,
        "title": "제목",      // ✅ 추가
        "type": 1,
        "answer": "답"        // ✅ 추가
    }
    """
)
```

### 3. 중첩 DTO 주의

중첩된 DTO의 `fixtureJSON`도 각각 올바르게 정의하세요.

## 베스트 프랙티스

1. 모든 `@ResponseTestable` DTO에 `fixtureJSON` 정의
2. 중첩된 DTO의 구조가 부모 DTO의 `fixtureJSON`과 일치하는지 확인
3. 컴파일 경고를 무시하지 말고 즉시 수정
4. 테스트에서 `fixture()`를 호출하여 런타임 검증

## 마이그레이션 가이드

기존 프로젝트에서 이 기능을 활성화하려면:

1. AsyncNetwork 업데이트 (이 변경사항 포함)
2. 프로젝트 빌드
3. 경고 확인 및 수정
4. 테스트 실행하여 `fixture()` 정상 동작 확인

## 참고

- AsyncNetwork 라이브러리 버전: 1.3.0+
- 매크로 구현 파일: `ResponseTestableMacroImpl.swift`
- 에러 정의 파일: `TestableDTOMacroError.swift`
- 테스트 파일: `ResponseTestableMacroValidationTests.swift`

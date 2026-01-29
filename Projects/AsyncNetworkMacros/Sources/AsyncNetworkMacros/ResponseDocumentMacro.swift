//
//  ResponseDocumentMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/12.
//

@_exported import AsyncNetworkCore

/// Codable 응답 모델에 OpenAPI 문서화를 위한 JSON 샘플을 추가하는 매크로
///
/// 이 매크로는 struct에 `jsonSample` 정적 프로퍼티를 자동 생성하여
/// OpenAPI 문서의 `example` 필드를 제공합니다.
///
/// ## 주요 기능
///
/// - ✅ JSON 유효성을 컴파일 타임에 자동 검증
/// - ✅ UTF-8 인코딩 및 JSONSerialization 파싱 검증
/// - ✅ 빈 문자열 및 공백 검증
/// - ✅ 명확한 컴파일 에러 메시지 제공
/// - ✅ @ResponseTestable과 통합하여 테스트 데이터로도 활용 가능
///
/// ## 기본 사용법
///
/// ```swift
/// @ResponseDocument(
///     fixtureJSON: """
///     {
///       "id": 1,
///       "title": "Test Post",
///       "body": "This is a test post",
///       "userId": 1
///     }
///     """
/// )
/// struct PostDTO: Codable, Sendable {
///     let id: Int
///     let title: String
///     let body: String
///     let userId: Int
/// }
/// ```
///
/// ## 매크로 확장 결과
///
/// 매크로는 다음과 같은 코드를 자동으로 생성합니다:
///
/// ```swift
/// struct PostDTO: Codable, Sendable {
///     let id: Int
///     let title: String
///     let body: String
///     let userId: Int
///
///     /// JSON 샘플 문자열
///     ///
///     /// OpenAPI 문서 생성 시 사용되는 응답 예시입니다.
///     public static var jsonSample: String {
///         \"\"\"
///         {
///           "id": 1,
///           "title": "Test Post",
///           "body": "This is a test post",
///           "userId": 1
///         }
///         \"\"\"
///     }
/// }
/// ```
///
/// ## @ResponseTestable과 통합
///
/// @ResponseTestable과 함께 사용하면 테스트 데이터로도 활용됩니다:
///
/// ```swift
/// @ResponseTestable
/// @ResponseDocument(
///     fixtureJSON: """
///     {
///       "id": 42,
///       "name": "Test User"
///     }
///     """
/// )
/// struct UserDTO: Codable, Sendable {
///     let id: Int
///     let name: String
/// }
///
/// // 사용 예시
/// let user = UserDTO.fixture() // fixtureJSON 기반 고정 데이터
/// let random = UserDTO.mock()   // 랜덤 데이터
/// ```
///
/// ## OpenAPI 문서 생성
///
/// `Scripts/OpenAPI/ExportOpenAPI.swift`가 `jsonSample` 프로퍼티를 파싱하여
/// OpenAPI 스펙의 `example` 필드에 자동 삽입합니다:
///
/// ```json
/// {
///   "components": {
///     "schemas": {
///       "PostDTO": {
///         "type": "object",
///         "properties": {
///           "id": { "type": "integer" },
///           "title": { "type": "string" },
///           "body": { "type": "string" },
///           "userId": { "type": "integer" }
///         },
///         "example": {
///           "id": 1,
///           "title": "Test Post",
///           "body": "This is a test post",
///           "userId": 1
///         }
///       }
///     }
///   }
/// }
/// ```
///
/// ## 복잡한 JSON 예시
///
/// 중첩된 객체와 배열도 지원합니다:
///
/// ```swift
/// @ResponseDocument(
///     fixtureJSON: """
///     {
///       "user": {
///         "id": 42,
///         "profile": {
///           "name": "John Doe",
///           "email": "john@example.com"
///         }
///       },
///       "posts": [
///         {
///           "id": 1,
///           "title": "First Post"
///         }
///       ],
///       "metadata": {
///         "timestamp": "2026-01-29T10:00:00Z",
///         "version": "1.0"
///       }
///     }
///     """
/// )
/// struct ComplexResponseDTO: Codable, Sendable {
///     let user: User
///     let posts: [Post]
///     let metadata: Metadata
/// }
/// ```
///
/// ## 컴파일 에러
///
/// 매크로는 다음 경우 컴파일 타임에 에러를 발생시킵니다:
///
/// ### 1. struct가 아닌 타입에 적용
///
/// ```swift
/// @ResponseDocument(fixtureJSON: "{}")
/// class MyClass { } // ❌ 에러: struct에만 적용 가능
/// ```
///
/// ### 2. fixtureJSON 파라미터 누락
///
/// ```swift
/// @ResponseDocument
/// struct MyDTO { } // ❌ 에러: fixtureJSON 파라미터 필수
/// ```
///
/// ### 3. 빈 문자열 또는 공백
///
/// ```swift
/// @ResponseDocument(fixtureJSON: "")
/// struct MyDTO { } // ❌ 에러: 빈 문자열 불가
///
/// @ResponseDocument(fixtureJSON: "   ")
/// struct MyDTO { } // ❌ 에러: 공백만 있는 문자열 불가
/// ```
///
/// ### 4. 잘못된 JSON 형식
///
/// ```swift
/// @ResponseDocument(fixtureJSON: "not a json")
/// struct MyDTO { } // ❌ 에러: 유효하지 않은 JSON
///
/// @ResponseDocument(
///     fixtureJSON: """
///     {
///       "id": 1,
///       "name": "Test"
///     // 닫는 중괄호 누락
///     """
/// )
/// struct MyDTO { } // ❌ 에러: JSON 파싱 실패
/// ```
///
/// ## 모범 사례
///
/// 1. **실제 API 응답과 일치**: 가능한 한 실제 API 응답 형태를 사용하세요
/// 2. **@ResponseTestable과 함께 사용**: 문서화와 테스트를 동시에 해결
/// 3. **의미 있는 데이터**: "test", "sample" 같은 placeholder 대신 실제 도메인 데이터 사용
/// 4. **들여쓰기 유지**: JSON 가독성을 위해 적절한 들여쓰기 사용
/// 5. **한글 지원**: 한글이 포함된 JSON도 올바르게 처리됩니다
///
/// ## 제약사항
///
/// - struct에만 적용 가능 (class, enum, protocol은 불가)
/// - fixtureJSON은 유효한 JSON 문자열이어야 함
/// - JSON과 DTO 프로퍼티 일치 여부는 런타임에 검증 (컴파일 타임 아님)
///
@attached(member, names: named(jsonSample))
public macro ResponseDocument(
    /// OpenAPI 문서의 example로 사용될 JSON 문자열
    ///
    /// - 유효한 JSON 형식이어야 합니다
    /// - UTF-8 인코딩 가능해야 합니다
    /// - JSONSerialization으로 파싱 가능해야 합니다
    /// - 빈 문자열이나 공백만 있는 문자열은 불가합니다
    ///
    /// 예시:
    /// ```swift
    /// fixtureJSON: """
    /// {
    ///   "id": 1,
    ///   "name": "Example"
    /// }
    /// """
    /// ```
    fixtureJSON: String
) = #externalMacro(
    module: "AsyncNetworkMacrosImpl",
    type: "ResponseDocumentMacroImpl"
)

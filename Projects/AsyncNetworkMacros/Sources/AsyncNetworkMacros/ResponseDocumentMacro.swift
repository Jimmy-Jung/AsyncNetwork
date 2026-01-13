//
//  ResponseDocumentMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/12.
//

@_exported import AsyncNetworkCore

/// Codable 응답 모델에 OpenAPI 문서화를 위한 JSON 샘플을 추가하는 매크로
///
/// 이 매크로는 `@Response`와 함께 사용하여 OpenAPI 스펙 생성 시 `example` 필드를 제공합니다.
///
/// ## 사용 예시
///
/// ```swift
/// @Response
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
/// struct PostDTO: Codable {
///     let id: Int
///     let title: String
///     let body: String
///     let userId: Int
/// }
/// ```
///
/// ## 매크로 확장 결과
///
/// ```swift
/// struct PostDTO: Codable {
///     let id: Int
///     let title: String
///     let body: String
///     let userId: Int
///
///     // @ResponseDocument가 생성
///     static var jsonSample: String {
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
/// ## OpenAPI 연동
///
/// `Scripts/OpenAPI/ExportOpenAPI.swift`가 `jsonSample` 프로퍼티를 파싱하여
/// OpenAPI 스펙의 `example` 필드에 자동으로 삽입합니다:
///
/// ```json
/// {
///   "components": {
///     "schemas": {
///       "PostDTO": {
///         "type": "object",
///         "properties": { ... },
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
/// ## 주의사항
///
/// - `fixtureJSON`은 유효한 JSON 형식이어야 합니다
/// - DTO의 실제 프로퍼티와 일치해야 합니다 (검증은 런타임)
/// - OpenAPI 문서 생성 시에만 사용되며, 테스트 코드에는 영향을 주지 않습니다
@attached(member, names: named(jsonSample))
public macro ResponseDocument(
    fixtureJSON: String
) = #externalMacro(
    module: "AsyncNetworkMacrosImpl",
    type: "ResponseDocumentMacroImpl"
)

//
//  DocumentArguments.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/29.
//

/// @APIDocument 매크로 인자를 담는 구조체
///
/// `@APIDocument`의 세 가지 파라미터(title, description, tags)를
/// 타입 안전하게 표현합니다.
///
/// ## 사용 예시
/// ```swift
/// let args = DocumentArguments(
///     title: "Get all posts",
///     description: "포스트 목록을 조회합니다",
///     tags: ["Posts", "Read"]
/// )
/// ```
struct DocumentArguments {
    /// API 엔드포인트의 제목
    ///
    /// OpenAPI의 `summary` 필드로 매핑됩니다.
    /// 간결하고 명확한 동사+명사 형태를 권장합니다.
    ///
    /// 예시: "Get all posts", "Create user", "Delete comment"
    let title: String

    /// API 엔드포인트의 상세 설명
    ///
    /// OpenAPI의 `description` 필드로 매핑됩니다.
    /// 다중 라인 문자열 및 Markdown 문법을 지원합니다.
    ///
    /// 예시:
    /// ```
    /// """
    /// 사용자 정보를 조회합니다.
    ///
    /// ## 권한
    /// - 인증 필요: Yes
    /// """
    /// ```
    let description: String

    /// API 엔드포인트를 분류하는 태그 목록
    ///
    /// OpenAPI의 `tags` 배열로 매핑됩니다.
    /// Swagger UI에서 섹션으로 그룹화됩니다.
    ///
    /// 예시: ["Users", "Admin", "v1"]
    let tags: [String]
}

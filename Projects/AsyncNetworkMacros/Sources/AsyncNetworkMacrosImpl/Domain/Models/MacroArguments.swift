//
//  MacroArguments.swift
//  AsyncNetworkMacrosImpl
//
//  Created by jimmy on 2026/01/13.
//

/// 매크로 인자를 담는 도메인 모델
///
/// @APIRequest 매크로에 전달되는 모든 인자를 타입 안전하게 표현합니다.
public struct MacroArguments {
    /// 응답 타입 이름 (예: "Post", "[Post]")
    public let responseType: String

    /// API 엔드포인트 제목 (문서화용)
    public let title: String

    /// API 엔드포인트 설명 (문서화용)
    public let description: String

    /// 베이스 URL (예: "https://api.example.com")
    public let baseURL: String

    /// baseURL이 문자열 리터럴인지 표현식인지 구분
    public let isBaseURLLiteral: Bool

    /// 경로 (예: "/posts/{id}")
    public let path: String

    /// HTTP 메서드 (예: "get", "post")
    public let method: String

    /// 태그 목록 (문서화용)
    public let tags: [String]

    /// 선택적 경로 파라미터 (예: {id?})
    public let optionalPathParameters: Set<String>

    // MARK: - 테스트 관련 필드

    /// 테스트 시나리오 목록
    public let testScenarios: [String]

    /// 에러 예시 (상태 코드 -> JSON)
    public let errorExamples: [String: String]

    /// 재시도 테스트 포함 여부
    public let includeRetryTests: Bool

    /// 성능 테스트 포함 여부
    public let includePerformanceTests: Bool

    public init(
        responseType: String,
        title: String = "",
        description: String = "",
        baseURL: String,
        isBaseURLLiteral: Bool = true,
        path: String,
        method: String,
        tags: [String] = [],
        optionalPathParameters: Set<String> = [],
        testScenarios: [String] = [],
        errorExamples: [String: String] = [:],
        includeRetryTests: Bool = true,
        includePerformanceTests: Bool = false
    ) {
        self.responseType = responseType
        self.title = title
        self.description = description
        self.baseURL = baseURL
        self.isBaseURLLiteral = isBaseURLLiteral
        self.path = path
        self.method = method
        self.tags = tags
        self.optionalPathParameters = optionalPathParameters
        self.testScenarios = testScenarios
        self.errorExamples = errorExamples
        self.includeRetryTests = includeRetryTests
        self.includePerformanceTests = includePerformanceTests
    }
}

import Foundation

/// 매크로 검증 레벨
///
/// @APIRequest 매크로의 검증 강도를 조절합니다.
public enum ValidationLevel: String {
    /// 엄격한 검증: 모든 규칙을 강제하며, 위반 시 컴파일 에러
    ///
    /// - struct만 허용
    /// - 모든 필수 인자 검사
    /// - Property Wrapper 타입 검증
    /// - Path Parameter 존재 여부 확인
    case strict

    /// 중간 검증: 필수 규칙만 강제하고, 권장 사항은 경고
    ///
    /// - struct만 허용 (에러)
    /// - 필수 인자 검사 (에러)
    /// - Property Wrapper 타입 불일치 (경고)
    /// - Path Parameter 누락 (경고)
    case moderate

    /// 관대한 검증: 최소한의 규칙만 강제
    ///
    /// - struct만 허용 (에러)
    /// - 필수 인자 검사 (경고)
    /// - 나머지는 검증하지 않음
    case lenient

    /// 기본 검증 레벨
    public static var `default`: ValidationLevel { .strict }
}

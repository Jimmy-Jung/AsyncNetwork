/// Property Wrapper 정보를 담는 구조체
///
/// @PathParameter, @QueryParameter, @HeaderField, @CustomHeader 등의
/// Property Wrapper에서 추출한 정보를 저장합니다.
struct PropertyWrapperInfo {
    /// 프로퍼티 이름
    let name: String

    /// 프로퍼티 타입 (예: "String", "Int?")
    let type: String

    /// Property Wrapper 타입 (예: "PathParameter", "HeaderField")
    let wrapperType: String

    /// 필수 여부 (옵셔널이 아니면 true)
    let isRequired: Bool

    /// 헤더 키 (HeaderField, CustomHeader용)
    let headerKey: String?

    /// 기본값 (HeaderField, CustomHeader용)
    let defaultValue: String?
}

/// @ResponseTestable 매크로 인자를 담는 구조체
struct TestableDTOArguments {
    let mockStrategy: String
    let fixtureJSON: String?
    let includeBuilder: Bool
    let defaultArrayCount: Int
}

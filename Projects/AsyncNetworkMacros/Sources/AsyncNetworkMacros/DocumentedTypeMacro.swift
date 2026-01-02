//
//  DocumentedTypeMacro.swift
//  AsyncNetworkMacros
//
//  Created by jimmy on 2026/01/02.
//

@_exported import AsyncNetworkCore

/// 타입의 구조를 문서화하는 매크로
///
/// 이 매크로를 적용하면 타입의 프로퍼티 정보를 기반으로 `typeStructure`와 `relatedTypeNames` 정적 프로퍼티가 자동 생성됩니다.
/// 생성된 구조는 API 문서에서 Response 타입의 구조를 보여주는 데 사용됩니다.
///
/// ## 사용 예시
///
/// ```swift
/// @DocumentedType
/// struct Post: Codable {
///     let userId: Int
///     let id: Int
///     let title: String
///     let body: String
/// }
/// ```
///
/// ## 매크로 확장 결과
///
/// ```swift
/// struct Post: Codable {
///     let userId: Int
///     let id: Int
///     let title: String
///     let body: String
///
///     static var typeStructure: String {
///         """
///         struct Post {
///             let userId: Int
///             let id: Int
///             let title: String
///             let body: String
///         }
///         """
///     }
///
///     static var relatedTypeNames: [String] {
///         []  // 중첩된 커스텀 타입이 없음
///     }
/// }
/// ```
///
/// ## 중첩 타입 자동 탐지
///
/// 중첩 타입이 있는 경우, 매크로가 자동으로 탐지하여 `relatedTypeNames`에 추가합니다:
///
/// ```swift
/// @DocumentedType
/// struct Order: Codable {
///     let id: Int
///     let items: [OrderItem]        // ← 배열 타입 탐지
///     let shippingAddress: ShippingAddress  // ← 커스텀 타입 탐지
/// }
///
/// // 매크로 확장 후:
/// static var relatedTypeNames: [String] {
///     ["OrderItem", "ShippingAddress"]
/// }
///
/// @DocumentedType
/// struct OrderItem: Codable {
///     let productId: Int
///     let name: String
/// }
///
/// @DocumentedType
/// struct ShippingAddress: Codable {
///     let street: String
///     let city: String
/// }
/// ```
///
/// ## APIRequest와 함께 사용
///
/// ```swift
/// @APIRequest(
///     response: Order.self,  // ← Order.typeStructure와 relatedTypeNames 자동 감지
///     title: "Create order",
///     baseURL: "https://api.example.com",
///     path: "/orders",
///     method: "post"
/// )
/// struct CreateOrderRequest {}
/// ```
///
/// API 문서에서 `Order` 타입을 보여줄 때:
/// 1. `Order.typeStructure`로 메인 구조 표시
/// 2. `Order.relatedTypeNames`로 중첩 타입 이름 확인
/// 3. 각 중첩 타입의 `typeStructure`를 재귀적으로 조회
/// 4. 토글 버튼으로 펼쳐서 볼 수 있음
///
/// ## 주의사항
///
/// - `struct`와 `class`에 적용 가능
/// - 저장 프로퍼티만 문서화됨 (계산 프로퍼티 제외)
/// - 모든 중첩 타입에도 `@DocumentedType` 적용 필요
/// - 프리미티브 타입(Int, String, Double 등)은 `relatedTypeNames`에서 자동 제외
/// - `TypeStructureProvider` 프로토콜을 자동으로 채택함
@attached(member, names: named(typeStructure), named(relatedTypeNames), named(_register))
@attached(extension, conformances: TypeStructureProvider)
public macro DocumentedType() = #externalMacro(
    module: "AsyncNetworkMacrosImpl",
    type: "DocumentedTypeMacroImpl"
)

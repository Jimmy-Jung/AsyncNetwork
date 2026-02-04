//
//  PrimitiveArrayDTO.swift
//  AsyncNetworkSampleApp
//
//  Created by Jimmy on 2026/01/29.
//

import AsyncNetwork
import Foundation

/// 기본 타입 배열을 가진 DTO - 매크로 버그 테스트용
///
/// 이 DTO는 @ResponseTestable 매크로가 기본 타입 배열(`[Int]`, `[String]` 등)을
/// 올바르게 처리하는지 검증하기 위해 작성되었습니다.
///
/// ## 버그 시나리오
///
/// ### 문제 /// - `categoryIds: [Int]` → 매크로가 `Int.mock()` 생성 → 컴파일 에러
/// - `labels: [String]` → 매크로가 `String.mock()` 생성 → 컴파일 에러
/// - 기본 타입은 `.mock()` 메서드가 없음
///
/// ### 해결 /// - 배열 요소 타입을 재귀적으로 검사
/// - 기본 타입이면 `generateMockValue` 재호출
/// - `Int.random(in: 1...1000)`, `"Mock \(UUID())"` 등 직접 생성
///
@ResponseTestable
public struct ItemDTO: Codable, Sendable {
    /// 아이템 고유 ID
    public let id: Int

    /// 아이템 이름
    public let name: String

    /// 카테고리 ID 리스트
    public let categoryIds: [Int]

    /// 라벨 리스트
    public let labels: [String]

    /// 이미지 URL
    public let imageUrl: String

    /// 지속 시간
    public let duration: Int

    /// 우선순위
    public let priority: Int

    /// 설명
    public let description: String

    /// 평점 리스트
    public let ratings: [Double]?

    /// 메타데이터
    public let metadata: [String: String]?

    /// 연관 아이템 ID 리스트
    public let relatedIds: [Int]?
}

/// 간단한 기본 타입 배열을 가진 DTO
@ResponseTestable
public struct SelectionDTO: Codable, Sendable {
    public let title: String
    public let totalCount: Int

    /// 선택된 인덱스 리스트
    public let selectedIndices: [Int]
}

/// Set을 사용하는 DTO - Set<Int> 처리 검증
@ResponseTestable
public struct CategorySetDTO: Codable, Sendable {
    public let id: Int
    public let title: String

    /// 카테고리 ID 집합
    public let categoryIds: Set<Int>
}

/// 다차원 배열을 가진 DTO - [[Int]] 처리 검증
@ResponseTestable
public struct GridDTO: Codable, Sendable {
    public let id: Int
    public let title: String

    /// 2차원 배열
    public let data: [[Int]]
}

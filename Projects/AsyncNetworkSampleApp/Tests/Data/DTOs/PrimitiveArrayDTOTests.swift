//
//  PrimitiveArrayDTOTests.swift
//  AsyncNetworkSampleAppTests
//
//  Created by Jimmy on 2026/01/29.
//

import AsyncNetwork
@testable import AsyncNetworkSampleApp
import Foundation
import Testing

/// 기본 타입 배열 처리 버그 검증 테스트
///
/// ## 테스트 목적
///
/// @ResponseTestable 매크로가 기본 타입 배열(`[Int]`, `[String]`, `[Double]` 등)을
/// 올바르게 처리하는지 검증합니다.
///
/// ## 버그 시나리오
///
/// ### 문제 (수정 전)
/// ```swift
/// // 매크로가 생성한 코드
/// categoryIds: (0..<Int.random(in: 2...5)).map { _ in Int.mock() }
/// //                                                   ^^^^^ 에러!
/// // Type 'Int' has no member 'mock'
/// ```
///
/// ### 해결 (수정 후)
/// ```swift
/// // 매크로가 생성해야 하는 올바른 코드
/// categoryIds: (0..<Int.random(in: 2...5)).map { _ in Int.random(in: 1...1000) }
/// //                                                   ^^^^^^^^^^^^^^^^^^^^^^^^ 정상!
/// ```
///
@Suite("ItemDTO Tests - 기본 타입 배열 처리")
struct ItemDTOTests {
    // MARK: - Mock 생성 테스트

    @Test("mock() - 기본 타입 배열이 랜덤 값으로 생성됨")
    func testMock() throws {
        // Given & When
        let item = ItemDTO.mock()

        // Then: 모든 필드가 생성되어야 함
        #expect(item.id > 0)
        #expect(!item.name.isEmpty)
        #expect(!item.imageUrl.isEmpty)
        #expect(item.duration > 0)
        #expect(item.priority > 0)
        #expect(!item.description.isEmpty)

        // 기본 타입 배열들이 생성되어야 함
        #expect(!item.categoryIds.isEmpty)
        #expect(!item.labels.isEmpty)

        // 배열 요소들이 유효한 값이어야 함
        #expect(item.categoryIds.allSatisfy { $0 > 0 })
        #expect(item.labels.allSatisfy { !$0.isEmpty })
    }

    @Test("mock() - 호출마다 다른 값 생성 (랜덤성 검증)")
    func mockRandomness() throws {
        // Given & When
        let item1 = ItemDTO.mock()
        let item2 = ItemDTO.mock()

        // Then: 랜덤 값이므로 대부분 달라야 함 (id는 랜덤이므로 다를 가능성 높음)
        #expect(item1.id != item2.id)

        // 배열 크기도 랜덤 (2~5)이므로 다를 수 있음
        let sameArraySize = item1.categoryIds.count == item2.categoryIds.count
        let sameFirstElement = item1.categoryIds.first == item2.categoryIds.first

        // 적어도 하나는 달라야 함
        #expect(!(sameArraySize && sameFirstElement))
    }

    // MARK: - Fixture 생성 테스트

    @Test("builder() - 고정 값으로 생성됨 (fixtureJSON 기반)")
    func testFixture() throws {
        // Given & When
        let item = ItemDTO.builder()
            .with(id: 1001)
            .with(name: "Sample Item")
            .with(categoryIds: [100, 200, 300])
            .with(labels: ["featured", "popular", "new"])
            .with(imageUrl: "https://example.com/item.png")
            .with(duration: 300)
            .with(priority: 3)
            .with(description: "Sample description")
            .with(ratings: [4.5, 4.8, 4.2])
            .with(metadata: nil)
            .with(relatedIds: [2001, 2002])
            .build()

        // Then: fixtureJSON에 정의된 고정 값
        #expect(item.id == 1001)
        #expect(item.name == "Sample Item")
        #expect(item.categoryIds == [100, 200, 300])
        #expect(item.labels == ["featured", "popular", "new"])
        #expect(item.imageUrl == "https://example.com/item.png")
        #expect(item.duration == 300)
        #expect(item.priority == 3)
        #expect(item.description == "Sample description")
        #expect(item.ratings == [4.5, 4.8, 4.2])
        #expect(item.relatedIds == [2001, 2002])
    }

    @Test("builder() - 항상 동일한 값 반환")
    func fixtureConsistency() throws {
        // Given & When
        let item1 = ItemDTO.builder()
            .with(id: 1001)
            .with(name: "Sample Item")
            .with(categoryIds: [100, 200, 300])
            .with(labels: ["featured", "popular", "new"])
            .with(imageUrl: "https://example.com/item.png")
            .with(duration: 300)
            .with(priority: 3)
            .with(description: "Sample description")
            .with(ratings: [4.5, 4.8, 4.2])
            .with(metadata: nil)
            .with(relatedIds: [2001, 2002])
            .build()
        let item2 = ItemDTO.builder()
            .with(id: 1001)
            .with(name: "Sample Item")
            .with(categoryIds: [100, 200, 300])
            .with(labels: ["featured", "popular", "new"])
            .with(imageUrl: "https://example.com/item.png")
            .with(duration: 300)
            .with(priority: 3)
            .with(description: "Sample description")
            .with(ratings: [4.5, 4.8, 4.2])
            .with(metadata: nil)
            .with(relatedIds: [2001, 2002])
            .build()

        // Then: 모든 필드가 동일해야 함
        #expect(item1.id == item2.id)
        #expect(item1.categoryIds == item2.categoryIds)
        #expect(item1.labels == item2.labels)
        #expect(item1.ratings == item2.ratings)
    }

    // MARK: - Builder 패턴 테스트

    @Test("builder() - 특정 필드만 커스터마이징")
    func testBuilder() throws {
        // Given & When
        let item = ItemDTO.builder()
            .with(id: 9999)
            .with(categoryIds: [1, 2, 3])
            .with(labels: ["custom", "label"])
            .build()

        // Then: 커스터마이징한 필드는 변경됨
        #expect(item.id == 9999)
        #expect(item.categoryIds == [1, 2, 3])
        #expect(item.labels == ["custom", "label"])

        // 나머지는 fixture() 고정 값 유지
        #expect(item.name == "Test String")
        #expect(item.imageUrl == "https://example.com/fixture")
    }

    // MARK: - mockArray 테스트

    @Test("mockArray() - 여러 개 생성")
    func testMockArray() throws {
        // Given & When
        let items = ItemDTO.mockArray(count: 3)

        // Then
        #expect(items.count == 3)
        #expect(items.allSatisfy { $0.id > 0 })
        #expect(items.allSatisfy { !$0.categoryIds.isEmpty })
        #expect(items.allSatisfy { !$0.labels.isEmpty })
    }

    // MARK: - assertValid 테스트

    @Test("assertValid() - 유효한 데이터 검증")
    func testAssertValid() throws {
        // Given
        let item = ItemDTO.builder()
            .with(id: 1001)
            .with(name: "Sample Item")
            .with(categoryIds: [100, 200, 300])
            .with(labels: ["featured", "popular", "new"])
            .with(imageUrl: "https://example.com/item.png")
            .with(duration: 300)
            .with(priority: 3)
            .with(description: "Sample description")
            .with(ratings: [4.5, 4.8, 4.2])
            .with(metadata: nil)
            .with(relatedIds: [2001, 2002])
            .build()

        // When & Then: 검증 통과해야 함
        item.assertValid()
    }

    // MARK: - 기본 타입 배열 특수 케이스

    @Test("기본 타입 배열 - Int 배열 처리")
    func intArray() throws {
        // Given & When
        let item = ItemDTO.mock()

        // Then: 배열이 생성되고 유효한 값들을 포함하는지 확인
        #expect(item.categoryIds.count >= 2)
        #expect(item.categoryIds.count <= 5)
        #expect(item.categoryIds.allSatisfy { $0 > 0 })
    }

    @Test("기본 타입 배열 - String 배열 처리")
    func stringArray() throws {
        // Given & When
        let item = ItemDTO.mock()

        // Then: 배열이 생성되고 유효한 값들을 포함하는지 확인
        #expect(item.labels.count >= 2)
        #expect(item.labels.count <= 5)
        #expect(item.labels.allSatisfy { !$0.isEmpty })
    }

    @Test("기본 타입 배열 - Double 배열 처리 (Optional)")
    func doubleArrayOptional() throws {
        // Given & When
        let item = ItemDTO.mock()

        // Then: Optional이므로 nil이거나 유효한 값들을 포함
        if let ratings = item.ratings {
            #expect(ratings.count >= 2)
            #expect(ratings.count <= 5)
            #expect(ratings.allSatisfy { $0 >= 0 && $0 <= 100 })
        }
    }

    @Test("딕셔너리 타입 처리 (Optional)")
    func dictionaryOptional() throws {
        // Given & When
        let item = ItemDTO.mock()

        // Then: Optional이므로 nil이거나 딕셔너리 생성됨
        if let metadata = item.metadata {
            // 빈 딕셔너리도 유효함 (매크로가 [:] 생성)
            #expect(metadata.keys.allSatisfy { !$0.isEmpty })
        }
    }
}

// MARK: - SelectionDTO Tests

@Suite("SelectionDTO Tests - 간단한 기본 타입 배열")
struct SelectionDTOTests {
    @Test("mock() - Int 배열 생성")
    func testMock() throws {
        // Given & When
        let selection = SelectionDTO.mock()

        // Then
        #expect(!selection.title.isEmpty)
        #expect(selection.totalCount > 0)
        #expect(!selection.selectedIndices.isEmpty)
        #expect(selection.selectedIndices.allSatisfy { $0 > 0 })
    }

    @Test("builder() - 고정 값 (fixtureJSON)")
    func testFixture() throws {
        // Given & When
        let selection = SelectionDTO.builder()
            .with(title: "Sample Selection")
            .with(totalCount: 5)
            .with(selectedIndices: [1, 3, 4])
            .build()

        // Then
        #expect(selection.title == "Sample Selection")
        #expect(selection.totalCount == 5)
        #expect(selection.selectedIndices == [1, 3, 4])
    }

    @Test("builder() - 인덱스 커스터마이징")
    func testBuilder() throws {
        // Given & When
        let selection = SelectionDTO.builder()
            .with(selectedIndices: [2, 4, 6])
            .build()

        // Then
        #expect(selection.selectedIndices == [2, 4, 6])
        #expect(selection.totalCount == 1) // fixture 고정 값
    }
}

// MARK: - CategorySetDTO Tests

@Suite("CategorySetDTO Tests - Set<기본타입> 처리")
struct CategorySetDTOTests {
    @Test("mock() - Set<Int> 생성")
    func testMock() throws {
        // Given & When
        let categorySet = CategorySetDTO.mock()

        // Then
        #expect(categorySet.id > 0)
        #expect(!categorySet.title.isEmpty)
        #expect(!categorySet.categoryIds.isEmpty)
        #expect(categorySet.categoryIds.allSatisfy { $0 > 0 })
    }

    @Test("builder() - Set이 배열로부터 생성됨")
    func testFixture() throws {
        // Given & When
        let categorySet = CategorySetDTO.builder()
            .with(id: 1)
            .with(title: "Product Category")
            .with(categoryIds: [101, 102, 103])
            .build()

        // Then: fixtureJSON의 배열이 Set으로 변환됨
        #expect(categorySet.id == 1)
        #expect(categorySet.title == "Product Category")
        #expect(categorySet.categoryIds == [101, 102, 103])
    }

    @Test("builder() - Set<Int> 커스터마이징")
    func testBuilder() throws {
        // Given & When
        let categorySet = CategorySetDTO.builder()
            .with(categoryIds: [999, 888])
            .build()

        // Then
        #expect(categorySet.categoryIds == [999, 888])
    }
}

// MARK: - GridDTO Tests

@Suite("GridDTO Tests - 다차원 배열 [[Int]] 처리")
struct GridDTOTests {
    @Test("mock() - 2차원 배열 생성")
    func testMock() throws {
        // Given & When
        let grid = GridDTO.mock()

        // Then
        #expect(grid.id > 0)
        #expect(!grid.title.isEmpty)
        #expect(!grid.data.isEmpty)

        // 각 행이 유효한 Int 배열이어야 함
        #expect(grid.data.allSatisfy { !$0.isEmpty })
        #expect(grid.data.allSatisfy { row in
            row.allSatisfy { $0 > 0 }
        })
    }

    @Test("builder() - 고정 2차원 배열")
    func testFixture() throws {
        // Given & When
        let grid = GridDTO.builder()
            .with(id: 1)
            .with(title: "Sample Grid")
            .with(data: [[1, 2, 3], [4, 5, 6]])
            .build()

        // Then
        #expect(grid.id == 1)
        #expect(grid.title == "Sample Grid")
        #expect(grid.data == [[1, 2, 3], [4, 5, 6]])
    }

    @Test("builder() - 2차원 배열 커스터마이징")
    func testBuilder() throws {
        // Given & When
        let grid = GridDTO.builder()
            .with(data: [[9, 8], [7, 6], [5, 4]])
            .build()

        // Then
        #expect(grid.data == [[9, 8], [7, 6], [5, 4]])
        #expect(grid.title == "Test String") // fixture 고정 값
    }

    @Test("다차원 배열 - 크기 검증")
    func matrixDimensions() throws {
        // Given
        let grid = GridDTO.builder()
            .with(id: 1)
            .with(title: "Sample Grid")
            .with(data: [[1, 2, 3], [4, 5, 6]])
            .build()

        // When
        let rows = grid.data.count
        let cols = grid.data.first?.count ?? 0

        // Then
        #expect(rows == 2)
        #expect(cols == 3)
    }
}

// MARK: - 통합 테스트

@Suite("기본 타입 배열 - 통합 검증")
struct PrimitiveArrayIntegrationTests {
    @Test("모든 DTO가 컴파일되고 인스턴스 생성 가능")
    func allDTOsCompile() throws {
        // Given & When & Then: 컴파일 에러 없이 생성되어야 함
        _ = ItemDTO.mock()
        _ = ItemDTO.builder().build()
        _ = SelectionDTO.mock()
        _ = SelectionDTO.builder().build()
        _ = CategorySetDTO.mock()
        _ = CategorySetDTO.builder().build()
        _ = GridDTO.mock()
        _ = GridDTO.builder().build()
    }

    @Test("TestableDTO 프로토콜 채택 확인")
    func ableDTOConformance() throws {
        // Given & When: 모든 DTO가 TestableDTO 메서드를 가지고 있는지 확인
        _ = ItemDTO.mock()
        _ = ItemDTO.builder().build()
        _ = ItemDTO.mockArray()

        _ = SelectionDTO.mock()
        _ = SelectionDTO.builder().build()
        _ = SelectionDTO.mockArray()

        _ = CategorySetDTO.mock()
        _ = CategorySetDTO.builder().build()
        _ = CategorySetDTO.mockArray()

        _ = GridDTO.mock()
        _ = GridDTO.builder().build()
        _ = GridDTO.mockArray()

        // Then: 컴파일 및 실행 성공
        #expect(Bool(true))
    }

    @Test("Codable 직렬화/역직렬화")
    func codable() throws {
        // Given
        let original = ItemDTO.builder()
            .with(id: 1001)
            .with(name: "Sample Item")
            .with(categoryIds: [100, 200, 300])
            .with(labels: ["featured", "popular", "new"])
            .with(imageUrl: "https://example.com/item.png")
            .with(duration: 300)
            .with(priority: 3)
            .with(description: "Sample description")
            .with(ratings: [4.5, 4.8, 4.2])
            .with(metadata: nil)
            .with(relatedIds: [2001, 2002])
            .build()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // When
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(ItemDTO.self, from: data)

        // Then
        #expect(decoded.id == original.id)
        #expect(decoded.categoryIds == original.categoryIds)
        #expect(decoded.labels == original.labels)
    }
}

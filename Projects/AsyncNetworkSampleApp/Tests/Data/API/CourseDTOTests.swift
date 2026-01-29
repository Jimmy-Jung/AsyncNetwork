//
//  CourseDTOTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/29.
//  Note: Split into separate DTO test files for better organization
//

@testable import AsyncNetworkSampleApp
import Testing

@Suite("CourseDTO Tests")
struct CourseDTOTests {
    // MARK: - Mock Tests

    @Test("CourseDTO.mock()이 올바른 데이터를 생성하는지 확인")
    func courseDTOMock() throws {
        // When
        let mock = CourseDTO.mock()

        // Then
        #expect(!mock.id.isEmpty)
        #expect(!mock.title.isEmpty)
        #expect(!mock.description.isEmpty)

        // 검증
        mock.assertValid()
    }

    @Test("CourseDTO.mock()이 매번 다른 값을 생성하는지 확인")
    func courseDTOMockRandomness() {
        // When
        let mock1 = CourseDTO.mock()
        let mock2 = CourseDTO.mock()

        // Then - 랜덤이므로 값이 달라야 함
        #expect(mock1.id != mock2.id || mock1.title != mock2.title)
    }

    @Test("CourseDTO.mockArray()가 여러 개의 Mock을 생성하는지 확인")
    func courseDTOMockArray() throws {
        // When
        let mocks = CourseDTO.mockArray(count: 10)

        // Then
        #expect(mocks.count == 10)

        // 모든 Mock이 유효한지 확인
        for mock in mocks {
            mock.assertValid()
        }
    }

    @Test("CourseDTO.mockArray()가 기본 개수로 생성하는지 확인")
    func courseDTOMockArrayDefaultCount() {
        // When (defaultArrayCount: 5)
        let mocks = CourseDTO.mockArray()

        // Then
        #expect(mocks.count == 5)
    }

    // MARK: - Fixture Tests

    @Test("CourseDTO.fixture()가 일관된 데이터를 반환하는지 확인")
    func courseDTOFixture() {
        // When
        let fixture1 = CourseDTO.fixture()
        let fixture2 = CourseDTO.fixture()

        // Then - Fixture는 항상 동일한 값
        #expect(fixture1.id == fixture2.id)
        #expect(fixture1.title == fixture2.title)
        #expect(fixture1.description == fixture2.description)

        // fixtureJSON에 정의된 값과 일치
        #expect(fixture1.id == "course-001")
        #expect(fixture1.title == "Swift Programming Fundamentals")
        #expect(fixture1.description == "Learn the basics of Swift programming language")
    }

    // MARK: - Builder Tests

    @Test("CourseDTO.builder()가 커스텀 데이터를 생성하는지 확인")
    func courseDTOBuilder() throws {
        // Given
        let customId = "custom-course-999"
        let customTitle = "Advanced Swift Design Patterns"
        let customDescription = "Master advanced Swift architectural patterns"

        // When
        let custom = CourseDTO.builder()
            .with(id: customId)
            .with(title: customTitle)
            .with(description: customDescription)
            .build()

        // Then
        #expect(custom.id == customId)
        #expect(custom.title == customTitle)
        #expect(custom.description == customDescription)

        custom.assertValid()
    }

    @Test("Builder가 부분 수정을 지원하는지 확인")
    func courseDTOBuilderPartialUpdate() throws {
        // Given - 일부만 수정
        let custom = CourseDTO.builder()
            .with(id: "partial-course-001")
            .build()

        // Then
        #expect(custom.id == "partial-course-001")
        // 나머지는 Mock 기본값
        #expect(!custom.title.isEmpty)
        #expect(!custom.description.isEmpty)
    }
}

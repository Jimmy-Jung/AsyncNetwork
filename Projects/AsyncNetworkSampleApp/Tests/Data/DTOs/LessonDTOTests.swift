//
//  LessonDTOTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/29.
//  Split from CourseDTOTests.swift
//

@testable import AsyncNetworkSampleApp
import Testing

@Suite("LessonDTO Tests")
struct LessonDTOTests {
    // MARK: - Mock Tests

    @Test("LessonDTO.random()이 올바른 데이터를 생성하는지 확인")
    func lessonDTOMock() throws {
        // When
        let mock = LessonDTO.random()

        // Then
        #expect(!mock.id.isEmpty)
        #expect(!mock.title.isEmpty)

        // 검증
        mock.assertValid()
    }

    @Test("LessonDTO.random()이 매번 다른 값을 생성하는지 확인")
    func lessonDTOMockRandomness() {
        // When
        let mock1 = LessonDTO.random()
        let mock2 = LessonDTO.random()

        // Then
        #expect(mock1.id != mock2.id || mock1.title != mock2.title)
    }

    @Test("LessonDTO.randomArray()가 여러 개의 Mock을 생성하는지 확인")
    func lessonDTOMockArray() throws {
        // When
        let mocks = LessonDTO.randomArray(count: 10)

        // Then
        #expect(mocks.count == 10)

        for mock in mocks {
            mock.assertValid()
        }
    }

    @Test("LessonDTO.randomArray()가 기본 개수로 생성하는지 확인")
    func lessonDTOMockArrayDefaultCount() {
        // When
        let mocks = LessonDTO.randomArray()

        // Then
        #expect(mocks.count == 5)
    }

    // MARK: - Fixture Tests

    @Test("LessonDTO.fixture()가 일관된 데이터를 생성하는지 확인")
    func lessonDTOFixture() {
        // When
        let fixture1 = LessonDTO.fixture()
            .with(id: "lesson-001")
            .with(title: "Introduction to Variables")
            .build()
        let fixture2 = LessonDTO.fixture()
            .with(id: "lesson-001")
            .with(title: "Introduction to Variables")
            .build()

        // Then
        #expect(fixture1.id == fixture2.id)
        #expect(fixture1.title == fixture2.title)

        // fixtureJSON 값 확인
        #expect(fixture1.id == "lesson-001")
        #expect(fixture1.title == "Introduction to Variables")
    }

    // MARK: - Builder Tests

    @Test("LessonDTO.fixture()가 커스텀 데이터를 생성하는지 확인")
    func lessonDTOBuilder() throws {
        // Given
        let customId = "custom-lesson-999"
        let customTitle = "Advanced Functions"

        // When
        let custom = LessonDTO.fixture()
            .with(id: customId)
            .with(title: customTitle)
            .build()

        // Then
        #expect(custom.id == customId)
        #expect(custom.title == customTitle)

        custom.assertValid()
    }
}

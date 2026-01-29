//
//  GetCoursesResponseDTOTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/29.
//  Split from CourseDTOTests.swift
//

@testable import AsyncNetworkSampleApp
import Testing

@Suite("GetCoursesResponseDTO Tests")
struct GetCoursesResponseDTOTests {
    // MARK: - Mock Tests

    @Test("GetCoursesResponseDTO.mock()이 올바른 데이터를 생성하는지 확인")
    func getCoursesResponseDTOMock() throws {
        // When
        let mock = GetCoursesResponseDTO.mock()

        // Then
        #expect(!mock.items.isEmpty, "items가 비어있지 않아야 함")

        // 검증
        mock.assertValid()
    }

    @Test("GetCoursesResponseDTO.mock()이 매번 다른 값을 생성하는지 확인")
    func getCoursesResponseDTOMockRandomness() {
        // When
        let mock1 = GetCoursesResponseDTO.mock()
        let mock2 = GetCoursesResponseDTO.mock()

        // Then - items가 비어있지 않아야 함
        #expect(!mock1.items.isEmpty, "mock1.items가 비어있지 않아야 함")
        #expect(!mock2.items.isEmpty, "mock2.items가 비어있지 않아야 함")

        // items의 개수나 내용이 달라야 함 (안전하게 검증)
        if !mock1.items.isEmpty, !mock2.items.isEmpty {
            let differentItems = mock1.items.count != mock2.items.count ||
                mock1.items[0].id != mock2.items[0].id
            #expect(differentItems, "Mock이 랜덤하게 생성되어야 함")
        }
    }

    @Test("GetCoursesResponseDTO.mockArray()가 여러 개의 Mock을 생성하는지 확인")
    func getCoursesResponseDTOMockArray() throws {
        // When
        let mocks = GetCoursesResponseDTO.mockArray(count: 10)

        // Then
        #expect(mocks.count == 10)

        for mock in mocks {
            #expect(!mock.items.isEmpty, "각 Mock의 items가 비어있지 않아야 함")
            mock.assertValid()
        }
    }

    @Test("GetCoursesResponseDTO.mockArray()가 기본 개수로 생성하는지 확인")
    func getCoursesResponseDTOMockArrayDefaultCount() {
        // When
        let mocks = GetCoursesResponseDTO.mockArray()

        // Then
        #expect(mocks.count == 5)
    }

    // MARK: - Fixture Tests

    @Test("GetCoursesResponseDTO.fixture()가 일관된 데이터를 반환하는지 확인")
    func getCoursesResponseDTOFixture() {
        // When
        let fixture1 = GetCoursesResponseDTO.fixture()
        let fixture2 = GetCoursesResponseDTO.fixture()

        // Then - Fixture는 항상 동일한 값
        #expect(fixture1.items.count == fixture2.items.count)
        #expect(fixture1.nextToken == fixture2.nextToken)

        // fixtureJSON에 정의된 값과 일치
        #expect(fixture1.items.count == 2)
        #expect(fixture1.items[0].id == "course-001")
        #expect(fixture1.items[0].title == "Swift Programming Fundamentals")
        #expect(fixture1.items[1].id == "course-002")
        #expect(fixture1.items[1].title == "Advanced Swift Patterns")
        #expect(fixture1.nextToken == "eyJwYWdlIjoxfQ==")
    }

    // MARK: - Builder Tests

    @Test("GetCoursesResponseDTO.builder()가 커스텀 데이터를 생성하는지 확인")
    func getCoursesResponseDTOBuilder() throws {
        // Given
        let customCourse1 = CourseDTO.builder()
            .with(id: "custom-1")
            .with(title: "Custom Course 1")
            .with(description: "First custom course")
            .build()

        let customCourse2 = CourseDTO.builder()
            .with(id: "custom-2")
            .with(title: "Custom Course 2")
            .with(description: "Second custom course")
            .build()

        let customNextToken = "customToken123"

        // When
        let custom = GetCoursesResponseDTO.builder()
            .with(items: [customCourse1, customCourse2])
            .with(nextToken: customNextToken)
            .build()

        // Then
        #expect(custom.items.count == 2)
        #expect(custom.items[0].id == "custom-1")
        #expect(custom.items[1].id == "custom-2")
        #expect(custom.nextToken == customNextToken)

        custom.assertValid()
    }

    @Test("Builder가 부분 수정을 지원하는지 확인")
    func getCoursesResponseDTOBuilderPartialUpdate() throws {
        // Given - nextToken만 변경
        // Builder는 fixture()를 사용하여 초기화되므로
        // fixtureJSON의 items (2개)가 기본값으로 설정됨
        let custom = GetCoursesResponseDTO.builder()
            .with(nextToken: "partialToken")
            .build()

        // Debug: 실제 값 확인
        let fixture = GetCoursesResponseDTO.fixture()
        print("🔍 DEBUG: fixture.items.count = \(fixture.items.count)")
        print("🔍 DEBUG: custom.items.count = \(custom.items.count)")

        // Then
        #expect(custom.nextToken == "partialToken", "nextToken이 올바르게 설정되어야 함")

        // fixtureJSON에 2개의 items가 정의되어 있으므로
        // Builder 초기값도 2개의 items를 가져야 함
        #expect(!custom.items.isEmpty, "Builder는 fixture()의 items (2개)를 사용해야 하므로 빈 배열이 아니어야 함")

        if custom.items.count >= 2 {
            #expect(custom.items.count == 2, "fixtureJSON에 정의된 2개의 items를 가져야 함")
            // fixtureJSON 값 검증
            #expect(custom.items[0].id == "course-001")
            #expect(custom.items[1].id == "course-002")
        } else {
            Issue.record("❌ Builder가 fixture()의 items를 사용하지 않음. 매크로 변경사항이 적용되지 않았을 가능성")
        }
    }

    @Test("GetCoursesResponseDTO가 nextToken이 nil인 경우를 처리하는지 확인")
    func getCoursesResponseDTOWithoutNextToken() throws {
        // Given
        let custom = GetCoursesResponseDTO.builder()
            .with(items: CourseDTO.mockArray(count: 3))
            .with(nextToken: nil)
            .build()

        // Then
        #expect(custom.items.count == 3)
        #expect(custom.nextToken == nil)

        custom.assertValid()
    }
}

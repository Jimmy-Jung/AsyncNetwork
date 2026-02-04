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

    @Test("CourseDTO.random()이 올바른 데이터를 생성하는지 확인")
    func courseDTOMock() throws {
        // When
        let mock = CourseDTO.random()

        // Then
        #expect(!mock.id.isEmpty)
        #expect(!mock.title.isEmpty)
        #expect(!mock.description.isEmpty)

        // 검증
        mock.assertValid()
    }

    @Test("CourseDTO.random()이 매번 다른 값을 생성하는지 확인")
    func courseDTOMockRandomness() {
        // When
        let mock1 = CourseDTO.random()
        let mock2 = CourseDTO.random()

        // Then - 랜덤이므로 값이 달라야 함
        #expect(mock1.id != mock2.id || mock1.title != mock2.title)
    }

    @Test("CourseDTO.random()으로 여러 개의 데이터를 생성하는지 확인")
    func courseDTOMockArray() throws {
        // When
        let mocks = CourseDTO.randomArray(count: 10)

        // Then
        #expect(mocks.count == 10)

        // 모든 Mock이 유효한지 확인
        for mock in mocks {
            mock.assertValid()
        }
    }

    @Test("CourseDTO.randomArray()가 기본 개수로 생성하는지 확인")
    func courseDTOMockArrayDefaultCount() {
        // When
        let mocks = CourseDTO.randomArray()

        // Then
        #expect(mocks.count == 5)
    }

    // MARK: - Builder Tests

    @Test("CourseDTO.fixture()가 커스텀 데이터를 생성하는지 확인")
    func courseDTOBuilder() throws {
        // Given
        let customId = "custom-course-999"
        let customTitle = "Advanced Swift Design Patterns"
        let customDescription = "Master advanced Swift architectural patterns"

        // When
        let custom = CourseDTO.fixture()
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

    @Test("Builder가 부분 수정을 지원하는지 확인 (하이브리드 패턴)")
    func courseDTOBuilderPartialUpdate() throws {
        // Given - id만 고정, 나머지는 랜덤
        // Builder는 mock() 기반이므로 나머지 필드는 자동으로 랜덤 값 생성
        let custom = CourseDTO.fixture()
            .with(id: "partial-course-001")
            .build()

        // Then
        #expect(custom.id == "partial-course-001")
        // 나머지는 Mock 랜덤 값
        #expect(!custom.title.isEmpty)
        #expect(!custom.description.isEmpty)

        custom.assertValid()
    }

    // MARK: - Builder + Mock 하이브리드 패턴

    @Test("Pattern 1: 완전 랜덤 - mock()만 사용")
    func builderPattern1_FullyRandom() {
        // When - 모든 필드가 랜덤
        let random = CourseDTO.random()

        // Then - 매번 다른 값
        #expect(!random.id.isEmpty)
        #expect(!random.title.isEmpty)
        #expect(!random.description.isEmpty)
        random.assertValid()
    }

    @Test("Pattern 2: 완전 고정 - builder로 모든 필드 지정")
    func builderPattern2_FullyFixed() {
        // When - 모든 필드를 고정
        let fixed = CourseDTO.fixture()
            .with(id: "course-001")
            .with(title: "Swift Fundamentals")
            .with(description: "Learn Swift basics")
            .build()

        // Then - 항상 동일한 값
        #expect(fixed.id == "course-001")
        #expect(fixed.title == "Swift Fundamentals")
        #expect(fixed.description == "Learn Swift basics")
        fixed.assertValid()
    }

    @Test("Pattern 3: 하이브리드 - 일부만 고정, 나머지는 fixture")
    func builderPattern3_Hybrid() {
        // When - id만 커스터마이징, 나머지는 fixture 기본값
        let hybrid = CourseDTO.fixture()
            .with(id: "test-course-999")
            .build()

        // Then
        #expect(hybrid.id == "test-course-999") // 커스터마이징한 값
        #expect(!hybrid.title.isEmpty) // fixture 값
        #expect(!hybrid.description.isEmpty) // fixture 값

        // 여러 번 생성해도 같은 with() 값이면 동일한 결과
        let hybrid2 = CourseDTO.fixture()
            .with(id: "test-course-999")
            .build()

        #expect(hybrid.id == hybrid2.id) // id는 동일
        #expect(hybrid.title == hybrid2.title) // fixture 값도 동일
        #expect(hybrid.description == hybrid2.description) // fixture 값도 동일
    }

    @Test("Pattern 4: 배열 생성 - randomArray()로 여러 개 생성")
    func builderPattern4_Array() {
        // When - 여러 개의 랜덤 데이터 생성
        let courses = CourseDTO.randomArray(count: 10)

        // Then
        #expect(courses.count == 10)

        // 각 항목이 유효한지 확인
        for course in courses {
            course.assertValid()
        }

        // 각 항목이 다른 값을 가지는지 확인
        let ids = Set(courses.map { $0.id })
        #expect(ids.count == 10, "모든 ID가 유니크해야 함")
    }

    @Test("Pattern 5: Builder + 커스텀 배열 - 일부만 고정")
    func builderPattern5_CustomArray() {
        // When - 특정 조건의 Course들을 여러 개 생성
        let beginnerCourses = (1 ... 5).map { index in
            CourseDTO.fixture()
                .with(id: "beginner-\(index)")
                .with(title: "Beginner Course \(index)")
                // description은 랜덤
                .build()
        }

        // Then
        #expect(beginnerCourses.count == 5)

        for (index, course) in beginnerCourses.enumerated() {
            let expectedId = "beginner-\(index + 1)"
            let expectedTitle = "Beginner Course \(index + 1)"

            #expect(course.id == expectedId)
            #expect(course.title == expectedTitle)
            #expect(!course.description.isEmpty) // 랜덤 값
        }
    }

    @Test("Pattern 6: 실전 시나리오 - 특정 조건 테스트")
    func builderPattern6_RealWorldScenario() {
        // Scenario: "Swift"로 시작하는 ID를 가진 Course만 필터링하는 로직 테스트

        // Given - Swift 과정 3개, 다른 과정 2개 생성
        let swiftCourses = (1 ... 3).map { index in
            CourseDTO.fixture()
                .with(id: "swift-\(index)")
                .build()
        }

        let otherCourses = [
            CourseDTO.fixture().with(id: "python-101").build(),
            CourseDTO.fixture().with(id: "kotlin-basics").build()
        ]

        let allCourses = swiftCourses + otherCourses

        // When - "swift-"로 시작하는 Course 필터링
        let filteredSwiftCourses = allCourses.filter { $0.id.hasPrefix("swift-") }

        // Then
        #expect(filteredSwiftCourses.count == 3)

        for course in filteredSwiftCourses {
            #expect(course.id.hasPrefix("swift-"))
            course.assertValid()
        }
    }

    @Test("Pattern 7: 중첩 DTO - Builder + Mock 조합")
    func builderPattern7_NestedDTO() {
        // When - GetCoursesResponseDTO에 커스텀 Course 배열 주입
        let customCourse1 = CourseDTO.fixture()
            .with(id: "custom-1")
            .with(title: "Custom Course 1")
            .build()

        let customCourse2 = CourseDTO.fixture()
            .with(id: "custom-2")
            .build() // title, description은 랜덤

        let response = GetCoursesResponseDTO.fixture()
            .with(items: [customCourse1, customCourse2])
            .with(nextToken: "custom-token")
            .build()

        // Then
        #expect(response.items.count == 2)
        #expect(response.items[0].id == "custom-1")
        #expect(response.items[0].title == "Custom Course 1")
        #expect(response.items[1].id == "custom-2")
        #expect(!response.items[1].title.isEmpty) // 랜덤
        #expect(response.nextToken == "custom-token")
    }
}

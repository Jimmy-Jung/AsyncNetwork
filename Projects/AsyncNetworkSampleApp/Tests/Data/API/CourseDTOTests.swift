//
//  CourseDTOTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/29.
//

import Testing
@testable import AsyncNetworkSampleApp

// MARK: - CourseDTO Tests

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

// MARK: - LessonDTO Tests

@Suite("LessonDTO Tests")
struct LessonDTOTests {
    
    // MARK: - Mock Tests
    
    @Test("LessonDTO.mock()이 올바른 데이터를 생성하는지 확인")
    func lessonDTOMock() throws {
        // When
        let mock = LessonDTO.mock()
        
        // Then
        #expect(!mock.id.isEmpty)
        #expect(!mock.title.isEmpty)
        
        // 검증
        mock.assertValid()
    }
    
    @Test("LessonDTO.mock()이 매번 다른 값을 생성하는지 확인")
    func lessonDTOMockRandomness() {
        // When
        let mock1 = LessonDTO.mock()
        let mock2 = LessonDTO.mock()
        
        // Then
        #expect(mock1.id != mock2.id || mock1.title != mock2.title)
    }
    
    @Test("LessonDTO.mockArray()가 여러 개의 Mock을 생성하는지 확인")
    func lessonDTOMockArray() throws {
        // When
        let mocks = LessonDTO.mockArray(count: 10)
        
        // Then
        #expect(mocks.count == 10)
        
        for mock in mocks {
            mock.assertValid()
        }
    }
    
    @Test("LessonDTO.mockArray()가 기본 개수로 생성하는지 확인")
    func lessonDTOMockArrayDefaultCount() {
        // When
        let mocks = LessonDTO.mockArray()
        
        // Then
        #expect(mocks.count == 5)
    }
    
    // MARK: - Fixture Tests
    
    @Test("LessonDTO.fixture()가 일관된 데이터를 반환하는지 확인")
    func lessonDTOFixture() {
        // When
        let fixture1 = LessonDTO.fixture()
        let fixture2 = LessonDTO.fixture()
        
        // Then
        #expect(fixture1.id == fixture2.id)
        #expect(fixture1.title == fixture2.title)
        
        // fixtureJSON 값 확인
        #expect(fixture1.id == "lesson-001")
        #expect(fixture1.title == "Introduction to Variables")
    }
    
    // MARK: - Builder Tests
    
    @Test("LessonDTO.builder()가 커스텀 데이터를 생성하는지 확인")
    func lessonDTOBuilder() throws {
        // Given
        let customId = "custom-lesson-999"
        let customTitle = "Advanced Functions"
        
        // When
        let custom = LessonDTO.builder()
            .with(id: customId)
            .with(title: customTitle)
            .build()
        
        // Then
        #expect(custom.id == customId)
        #expect(custom.title == customTitle)
        
        custom.assertValid()
    }
}

// MARK: - ExerciseDTO Tests

@Suite("ExerciseDTO Tests")
struct ExerciseDTOTests {
    
    // MARK: - Mock Tests
    
    @Test("ExerciseDTO.mock()이 올바른 데이터를 생성하는지 확인")
    func exerciseDTOMock() throws {
        // When
        let mock = ExerciseDTO.mock()
        
        // Then
        #expect(!mock.id.isEmpty)
        #expect(!mock.question.isEmpty)
        
        // 검증
        mock.assertValid()
    }
    
    @Test("ExerciseDTO.mock()이 매번 다른 값을 생성하는지 확인")
    func exerciseDTOMockRandomness() {
        // When
        let mock1 = ExerciseDTO.mock()
        let mock2 = ExerciseDTO.mock()
        
        // Then
        #expect(mock1.id != mock2.id || mock1.question != mock2.question)
    }
    
    @Test("ExerciseDTO.mockArray()가 여러 개의 Mock을 생성하는지 확인")
    func exerciseDTOMockArray() throws {
        // When
        let mocks = ExerciseDTO.mockArray(count: 10)
        
        // Then
        #expect(mocks.count == 10)
        
        for mock in mocks {
            mock.assertValid()
        }
    }
    
    @Test("ExerciseDTO.mockArray()가 기본 개수로 생성하는지 확인")
    func exerciseDTOMockArrayDefaultCount() {
        // When
        let mocks = ExerciseDTO.mockArray()
        
        // Then
        #expect(mocks.count == 5)
    }
    
    // MARK: - Fixture Tests
    
    @Test("ExerciseDTO.fixture()가 일관된 데이터를 반환하는지 확인")
    func exerciseDTOFixture() {
        // When
        let fixture1 = ExerciseDTO.fixture()
        let fixture2 = ExerciseDTO.fixture()
        
        // Then
        #expect(fixture1.id == fixture2.id)
        #expect(fixture1.question == fixture2.question)
        
        // fixtureJSON 값 확인
        #expect(fixture1.id == "exercise-001")
        #expect(fixture1.question == "What is a variable in Swift?")
    }
    
    // MARK: - Builder Tests
    
    @Test("ExerciseDTO.builder()가 커스텀 데이터를 생성하는지 확인")
    func exerciseDTOBuilder() throws {
        // Given
        let customId = "custom-exercise-999"
        let customQuestion = "What is the difference between struct and class?"
        
        // When
        let custom = ExerciseDTO.builder()
            .with(id: customId)
            .with(question: customQuestion)
            .build()
        
        // Then
        #expect(custom.id == customId)
        #expect(custom.question == customQuestion)
        
        custom.assertValid()
    }
}

// MARK: - GetCoursesResponseDTO Tests

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
        if !mock1.items.isEmpty && !mock2.items.isEmpty {
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
        let custom = GetCoursesResponseDTO.builder()
            .with(nextToken: "partialToken")
            .build()
        
        // Then
        #expect(custom.nextToken == "partialToken")
        #expect(!custom.items.isEmpty)
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

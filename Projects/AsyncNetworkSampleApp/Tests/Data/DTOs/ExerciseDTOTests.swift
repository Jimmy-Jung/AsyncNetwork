//
//  ExerciseDTOTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/29.
//  Split from CourseDTOTests.swift
//

@testable import AsyncNetworkSampleApp
import Testing

@Suite("ExerciseDTO Tests")
struct ExerciseDTOTests {
    // MARK: - Mock Tests

    @Test("ExerciseDTO.random()이 올바른 데이터를 생성하는지 확인")
    func exerciseDTOMock() throws {
        // When
        let mock = ExerciseDTO.random()

        // Then
        #expect(!mock.id.isEmpty)
        #expect(!mock.question.isEmpty)

        // 검증
        mock.assertValid()
    }

    @Test("ExerciseDTO.random()이 매번 다른 값을 생성하는지 확인")
    func exerciseDTOMockRandomness() {
        // When
        let mock1 = ExerciseDTO.random()
        let mock2 = ExerciseDTO.random()

        // Then
        #expect(mock1.id != mock2.id || mock1.question != mock2.question)
    }

    @Test("ExerciseDTO.random()으로 여러 개의 데이터를 생성하는지 확인")
    func exerciseDTOMockArray() throws {
        // When
        let mocks = ExerciseDTO.randomArray(count: 10)

        // Then
        #expect(mocks.count == 10)

        for mock in mocks {
            mock.assertValid()
        }
    }

    @Test("ExerciseDTO.randomArray()가 기본 개수로 생성하는지 확인")
    func exerciseDTOMockArrayDefaultCount() {
        // When
        let mocks = ExerciseDTO.randomArray()

        // Then
        #expect(mocks.count == 5)
    }

    // MARK: - Fixture Tests

    @Test("ExerciseDTO.fixture()가 일관된 데이터를 생성하는지 확인")
    func exerciseDTOFixture() {
        // When
        let fixture1 = ExerciseDTO.fixture()
            .with(id: "exercise-001")
            .with(question: "What is a variable in Swift?")
            .build()
        let fixture2 = ExerciseDTO.fixture()
            .with(id: "exercise-001")
            .with(question: "What is a variable in Swift?")
            .build()

        // Then
        #expect(fixture1.id == fixture2.id)
        #expect(fixture1.question == fixture2.question)

        // 고정 값 확인
        #expect(fixture1.id == "exercise-001")
        #expect(fixture1.question == "What is a variable in Swift?")
    }

    // MARK: - Builder Tests

    @Test("ExerciseDTO.fixture()가 커스텀 데이터를 생성하는지 확인")
    func exerciseDTOBuilder() throws {
        // Given
        let customId = "custom-exercise-999"
        let customQuestion = "What is the difference between struct and class?"

        // When
        let custom = ExerciseDTO.fixture()
            .with(id: customId)
            .with(question: customQuestion)
            .build()

        // Then
        #expect(custom.id == customId)
        #expect(custom.question == customQuestion)

        custom.assertValid()
    }
}

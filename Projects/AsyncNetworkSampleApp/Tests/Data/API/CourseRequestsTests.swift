//
//  CourseRequestsTests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/28.
//

import AsyncNetwork
import Testing

@testable import AsyncNetworkSampleApp

@Suite("Course Requests Tests - Metadata Generation")
struct CourseRequestsTests {
    
    // MARK: - Test @APIDocument 없는 경우 (버그 재현)
    
    @Test("GetCoursesRequestWithoutDocument should compile with generated metadata")
    func testGetCoursesWithoutDocument() async throws {
        // Given
        let request = GetCoursesRequestWithoutDocument(
            pageSize: 10,
            sortBy: "createdAt",
            authorization: "Bearer token"
        )
        
        // Then - 컴파일 성공 확인
        #expect(request.pageSize == 10)
        #expect(request.sortBy == "createdAt")
        #expect(request.authorization == "Bearer token")
        
        // Metadata 접근 가능 확인
        let metadata = GetCoursesRequestWithoutDocument.metadata
        #expect(metadata.id == "GetCoursesRequestWithoutDocument")
        #expect(metadata.method == "GET")
        #expect(metadata.path == "/v1/courses")
        #expect(metadata.responseTypeName == "GetCoursesResponseDTO")
    }
    
    // MARK: - Test @APIDocument 있는 경우
    
    @Test("GetCoursesRequest should have complete metadata")
    func testGetCoursesMetadata() async throws {
        // Given
        let metadata = GetCoursesRequest.metadata
        
        // Then
        #expect(metadata.id == "GetCoursesRequest")
        #expect(metadata.title == "GET Courses")
        #expect(metadata.description == "Retrieve list of courses with pagination and filtering")
        #expect(metadata.method == "GET")
        #expect(metadata.path == "/v1/courses")
        #expect(metadata.baseURLString == learningPlatformBaseURL)
        #expect(metadata.tags.contains("Courses"))
        #expect(metadata.responseTypeName == "GetCoursesResponseDTO")
    }
    
    @Test("GetCourseRequest should have complete metadata with error responses")
    func testGetCourseMetadata() async throws {
        // Given
        let metadata = GetCourseRequest.metadata
        
        // Then
        #expect(metadata.id == "GetCourseRequest")
        #expect(metadata.title == "GET Course")
        #expect(metadata.method == "GET")
        #expect(metadata.path == "/v1/courses/{courseId}")
        #expect(metadata.parameters.contains("courseId"))
    }
    
    @Test("PostCourseRequest should have metadata with body parameter")
    func testPostCourseMetadata() async throws {
        // Given
        let metadata = PostCourseRequest.metadata
        
        // Then
        #expect(metadata.id == "PostCourseRequest")
        #expect(metadata.title == "POST Course")
        #expect(metadata.method == "POST")
        #expect(metadata.path == "/v1/courses")
        #expect(metadata.headers["Content-Type"] == "application/json")
    }
    
    @Test("PatchCourseRequest should have metadata with path parameter")
    func testPatchCourseMetadata() async throws {
        // Given
        let metadata = PatchCourseRequest.metadata
        
        // Then
        #expect(metadata.id == "PatchCourseRequest")
        #expect(metadata.title == "PATCH Course")
        #expect(metadata.method == "PATCH")
        #expect(metadata.path == "/v1/courses/{courseId}")
        #expect(metadata.parameters.contains("courseId"))
    }
    
    @Test("PatchLessonRequest should have metadata with multiple path parameters")
    func testPatchLessonMetadata() async throws {
        // Given
        let metadata = PatchLessonRequest.metadata
        
        // Then
        #expect(metadata.id == "PatchLessonRequest")
        #expect(metadata.title == "PATCH Lesson")
        #expect(metadata.method == "PATCH")
        #expect(metadata.path == "/v1/courses/{courseId}/lessons/{lessonId}")
        #expect(metadata.parameters.contains("courseId"))
        #expect(metadata.parameters.contains("lessonId"))
    }
    
    @Test("PatchExerciseRequest should have metadata with three path parameters")
    func testPatchExerciseMetadata() async throws {
        // Given
        let metadata = PatchExerciseRequest.metadata
        
        // Then
        #expect(metadata.id == "PatchExerciseRequest")
        #expect(metadata.title == "PATCH Exercise")
        #expect(metadata.method == "PATCH")
        #expect(metadata.path == "/v1/courses/{courseId}/lessons/{lessonId}/exercises/{exerciseId}")
        #expect(metadata.parameters.contains("courseId"))
        #expect(metadata.parameters.contains("lessonId"))
        #expect(metadata.parameters.contains("exerciseId"))
    }
    
    // MARK: - Test Request Creation
    
    @Test("PatchExerciseRequest should be created successfully")
    func testPatchExerciseCreation() async throws {
        // Given
        let body = PatchExerciseBody(question: "Updated question")
        
        // When
        let request = PatchExerciseRequest(
            courseId: "course-1",
            lessonId: "lesson-1",
            exerciseId: "exercise-1",
            body: body,
            authorization: "Bearer token"
        )
        
        // Then
        #expect(request.courseId == "course-1")
        #expect(request.lessonId == "lesson-1")
        #expect(request.exerciseId == "exercise-1")
        #expect(request.body?.question == "Updated question")
        #expect(request.authorization == "Bearer token")
        #expect(request.contentType == "application/json")
    }
    
    // MARK: - Test Backward Compatibility
    
    @Test("Requests without @APIDocument should still compile and work")
    func testBackwardCompatibility() async throws {
        // Given - @APIDocument 없는 Request
        let request = GetCoursesRequestWithoutDocument(
            pageSize: 20,
            sortBy: "updatedAt",
            instructorId: "instructor-1",
            authorization: "Bearer token"
        )
        
        // When - APIRequest 프로토콜 준수 확인
        #expect(request.baseURLString == learningPlatformBaseURL)
        #expect(request.path == "/v1/courses")
        #expect(request.method == .get)
        
        // Then - Metadata 접근 가능
        let metadata = GetCoursesRequestWithoutDocument.metadata
        #expect(metadata.id == "GetCoursesRequestWithoutDocument")
        #expect(metadata.method == "GET")
        #expect(metadata.baseURLString == learningPlatformBaseURL)
        #expect(metadata.responseTypeName == "GetCoursesResponseDTO")
    }
}

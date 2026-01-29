//
//  CourseRequests.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/28.
//

import AsyncNetwork
import Foundation

// MARK: - Get Courses (without @APIDocument)

@APIRequest(
    response: GetCoursesResponseDTO.self,
    baseURL: learningPlatformBaseURL,
    path: "/v1/courses",
    method: .get
)
struct GetCoursesRequestWithoutDocument {
    @QueryParameter var pageSize: Int // 필수 파라미터
    @QueryParameter var sortBy: String // 필수 파라미터
    @QueryParameter var nextToken: String? // 비필수 파라미터
    @QueryParameter var instructorId: String?
    @QueryParameter var categoryId: String?
    @QueryParameter var levelId: String?
    @QueryParameter var include: [String]?
    @HeaderField(key: .authorization) var authorization: String?

    init(
        pageSize: Int,
        sortBy: String,
        nextToken: String? = nil,
        instructorId: String? = nil,
        categoryId: String? = nil,
        levelId: String? = nil,
        include: [String]? = nil,
        authorization: String?
    ) {
        self.pageSize = pageSize
        self.sortBy = sortBy
        self.nextToken = nextToken
        self.instructorId = instructorId
        self.categoryId = categoryId
        self.levelId = levelId
        self.include = include
        self.authorization = authorization
    }
}

// MARK: - Get Courses (with @APIDocument)

@APIRequest(
    response: GetCoursesResponseDTO.self,
    baseURL: learningPlatformBaseURL,
    path: "/v1/courses",
    method: .get
)
@APIDocument(
    title: "GET Courses",
    description: "Retrieve list of courses with pagination and filtering",
    tags: ["Courses"]
)
struct GetCoursesRequest {
    @QueryParameter var pageSize: Int // 필수 파라미터
    @QueryParameter var sortBy: String // 필수 파라미터
    @QueryParameter var nextToken: String? // 비필수 파라미터
    @QueryParameter var instructorId: String?
    @QueryParameter var categoryId: String?
    @QueryParameter var levelId: String?
    @QueryParameter var include: [String]?
    @HeaderField(key: .authorization) var authorization: String?

    init(
        pageSize: Int,
        sortBy: String,
        nextToken: String? = nil,
        instructorId: String? = nil,
        categoryId: String? = nil,
        levelId: String? = nil,
        include: [String]? = nil,
        authorization: String?
    ) {
        self.pageSize = pageSize
        self.sortBy = sortBy
        self.nextToken = nextToken
        self.instructorId = instructorId
        self.categoryId = categoryId
        self.levelId = levelId
        self.include = include
        self.authorization = authorization
    }
}

// MARK: - Get Course

@APIRequest(
    response: CourseDTO.self,
    baseURL: learningPlatformBaseURL,
    path: "/v1/courses/{courseId}",
    method: .get,
    errorResponses: [
        404: NotFoundErrorDTO.self
    ]
)
@APIDocument(
    title: "GET Course",
    description: "Retrieve a single course by ID",
    tags: ["Courses"]
)
struct GetCourseRequest {
    @PathParameter var courseId: String
    @QueryParameter var include: [String]?
    @HeaderField(key: .authorization) var authorization: String?

    init(
        courseId: String,
        include: [String]? = nil,
        authorization: String?
    ) {
        self.courseId = courseId
        self.include = include
        self.authorization = authorization
    }
}

// MARK: - Post Course

@APIRequest(
    response: CourseDTO.self,
    baseURL: learningPlatformBaseURL,
    path: "/v1/courses",
    method: .post
)
@APIDocument(
    title: "POST Course",
    description: "Create a new course",
    tags: ["Courses"]
)
struct PostCourseRequest {
    @RequestBody var body: PostCourseBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
}

// MARK: - Patch Course

@APIRequest(
    response: CourseDTO.self,
    baseURL: learningPlatformBaseURL,
    path: "/v1/courses/{courseId}",
    method: .patch
)
@APIDocument(
    title: "PATCH Course",
    description: "Update course information",
    tags: ["Courses"]
)
struct PatchCourseRequest {
    @PathParameter var courseId: String
    @RequestBody var body: PatchCourseBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
}

// MARK: - Patch Lesson

@APIRequest(
    response: LessonDTO.self,
    baseURL: learningPlatformBaseURL,
    path: "/v1/courses/{courseId}/lessons/{lessonId}",
    method: .patch
)
@APIDocument(
    title: "PATCH Lesson",
    description: "Update lesson content",
    tags: ["Courses", "Lessons"]
)
struct PatchLessonRequest {
    @PathParameter var courseId: String
    @PathParameter var lessonId: String
    @RequestBody var body: PatchLessonBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
}

// MARK: - Patch Exercise

@APIRequest(
    response: ExerciseDTO.self,
    baseURL: learningPlatformBaseURL,
    path: "/v1/courses/{courseId}/lessons/{lessonId}/exercises/{exerciseId}",
    method: .patch
)
@APIDocument(
    title: "PATCH Exercise",
    description: "Update exercise question or answer",
    tags: ["Courses", "Lessons", "Exercises"]
)
struct PatchExerciseRequest {
    @PathParameter var courseId: String
    @PathParameter var lessonId: String
    @PathParameter var exerciseId: String
    @RequestBody var body: PatchExerciseBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
}

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
struct PostCourseRequest {
    @RequestBody var body: PostCourseBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    
    init(
        body: PostCourseBody? = nil,
        authorization: String? = nil,
        contentType: String? = "application/json"
    ) {
        self.body = body
        self.authorization = authorization
        self.contentType = contentType
    }
}

// MARK: - Patch Course

@APIRequest(
    response: CourseDTO.self,
    baseURL: learningPlatformBaseURL,
    path: "/v1/courses/{courseId}",
    method: .patch
)
struct PatchCourseRequest {
    @PathParameter var courseId: String
    @RequestBody var body: PatchCourseBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    
    init(
        courseId: String,
        body: PatchCourseBody? = nil,
        authorization: String? = nil,
        contentType: String? = "application/json"
    ) {
        self.courseId = courseId
        self.body = body
        self.authorization = authorization
        self.contentType = contentType
    }
}

// MARK: - Patch Lesson

@APIRequest(
    response: LessonDTO.self,
    baseURL: learningPlatformBaseURL,
    path: "/v1/courses/{courseId}/lessons/{lessonId}",
    method: .patch
)
struct PatchLessonRequest {
    @PathParameter var courseId: String
    @PathParameter var lessonId: String
    @RequestBody var body: PatchLessonBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    
    init(
        courseId: String,
        lessonId: String,
        body: PatchLessonBody? = nil,
        authorization: String? = nil,
        contentType: String? = "application/json"
    ) {
        self.courseId = courseId
        self.lessonId = lessonId
        self.body = body
        self.authorization = authorization
        self.contentType = contentType
    }
}

// MARK: - Patch Exercise

@APIRequest(
    response: ExerciseDTO.self,
    baseURL: learningPlatformBaseURL,
    path: "/v1/courses/{courseId}/lessons/{lessonId}/exercises/{exerciseId}",
    method: .patch
)
struct PatchExerciseRequest {
    @PathParameter var courseId: String
    @PathParameter var lessonId: String
    @PathParameter var exerciseId: String
    @RequestBody var body: PatchExerciseBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    
    init(
        courseId: String,
        lessonId: String,
        exerciseId: String,
        body: PatchExerciseBody? = nil,
        authorization: String? = nil,
        contentType: String? = "application/json"
    ) {
        self.courseId = courseId
        self.lessonId = lessonId
        self.exerciseId = exerciseId
        self.body = body
        self.authorization = authorization
        self.contentType = contentType
    }
}

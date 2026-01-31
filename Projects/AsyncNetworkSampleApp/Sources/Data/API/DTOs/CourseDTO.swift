//
//  CourseDTO.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/28.
//

import AsyncNetwork
import Foundation

// MARK: - Course API Base URL

let learningPlatformBaseURL: String = "https://api.learning-platform.example.com"

// MARK: - Response DTOs

@ResponseTestable
struct CourseDTO: Codable, Sendable {
    let id: String
    let title: String
    let description: String
}

@ResponseTestable
struct LessonDTO: Codable, Sendable {
    let id: String
    let title: String
}

@ResponseTestable
struct ExerciseDTO: Codable, Sendable {
    let id: String
    let question: String
}

@ResponseTestable
struct GetCoursesResponseDTO: Codable, Sendable {
    let items: [CourseDTO]
    let nextToken: String?
}

// MARK: - Request Body DTOs

struct PostCourseBody: Codable, Sendable {
    let title: String
    let description: String
}

struct PatchCourseBody: Codable, Sendable {
    let title: String?
    let description: String?
}

struct PatchLessonBody: Codable, Sendable {
    let title: String?
}

struct PatchExerciseBody: Codable, Sendable {
    let question: String?
}

// MARK: - Error DTOs

struct NotFoundErrorDTO: Codable, Sendable, Error {
    let error: String
    let code: String
}

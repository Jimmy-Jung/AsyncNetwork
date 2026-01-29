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

@ResponseDocument(
    fixtureJSON: """
    {
      "id": "course-001",
      "title": "Swift Programming Fundamentals",
      "description": "Learn the basics of Swift programming language"
    }
    """
)
@ResponseTestable(
    mockStrategy: .random,
    includeBuilder: true,
    defaultArrayCount: 5
)
struct CourseDTO: Codable, Sendable {
    let id: String
    let title: String
    let description: String
}

@ResponseDocument(
    fixtureJSON: """
    {
      "id": "lesson-001",
      "title": "Introduction to Variables"
    }
    """
)
@ResponseTestable(
    mockStrategy: .random,
    includeBuilder: true,
    defaultArrayCount: 5
)
struct LessonDTO: Codable, Sendable {
    let id: String
    let title: String
}

@ResponseDocument(
    fixtureJSON: """
    {
      "id": "exercise-001",
      "question": "What is a variable in Swift?"
    }
    """
)
@ResponseTestable(
    mockStrategy: .random,
    includeBuilder: true,
    defaultArrayCount: 5
)
struct ExerciseDTO: Codable, Sendable {
    let id: String
    let question: String
}

@ResponseDocument(
    fixtureJSON: """
    {
      "items": [
        {
          "id": "course-001",
          "title": "Swift Programming Fundamentals",
          "description": "Learn the basics of Swift programming language"
        },
        {
          "id": "course-002",
          "title": "Advanced Swift Patterns",
          "description": "Master advanced Swift design patterns"
        }
      ],
      "nextToken": "eyJwYWdlIjoxfQ=="
    }
    """
)
@ResponseTestable(
    mockStrategy: .random,
    includeBuilder: true,
    defaultArrayCount: 5
)
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

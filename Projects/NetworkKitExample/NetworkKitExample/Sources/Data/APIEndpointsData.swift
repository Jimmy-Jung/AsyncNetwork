//
//  APIEndpointsData.swift
//  NetworkKitExample
//
//  Created by jimmy on 2025/12/29.
//

import Foundation
import NetworkKit

enum APIEndpointsData {
    static let all: [APIEndpoint] = [
        // MARK: - Posts

        .getPosts,
        .getPostById,
        .createPost,
        .updatePost,
        .deletePost,

        // MARK: - Users

        .getUsers,
        .getUserById,
        .createUser,

        // MARK: - Comments

        .getComments,
        .getCommentsByPostId,

        // MARK: - Todos

        .getTodos,
        .getTodoById,
    ]

    static var categories: [String] {
        Array(Set(all.map { $0.category })).sorted()
    }

    static func endpoints(for category: String) -> [APIEndpoint] {
        all.filter { $0.category == category }
    }
}

// MARK: - Posts Endpoints

extension APIEndpoint {
    static let getPosts = APIEndpoint(
        id: "get-posts",
        category: "Posts",
        method: .get,
        path: "/posts",
        summary: "Get all posts",
        description: "Retrieve a list of all posts from JSONPlaceholder.",
        parameters: [
            APIParameter(
                name: "userId",
                location: .query,
                type: "integer",
                description: "Filter posts by user ID",
                example: "1"
            ),
        ],
        responses: [
            APIResponse(
                statusCode: 200,
                description: "Successful response",
                schema: "Array<Post>",
                example: """
                [
                  {
                    "userId": 1,
                    "id": 1,
                    "title": "sunt aut facere repellat",
                    "body": "quia et suscipit..."
                  }
                ]
                """
            ),
        ]
    )

    static let getPostById = APIEndpoint(
        id: "get-post-by-id",
        category: "Posts",
        method: .get,
        path: "/posts/{id}",
        summary: "Get a post by ID",
        description: "Retrieve a specific post by its ID.",
        parameters: [
            APIParameter(
                name: "id",
                location: .path,
                type: "integer",
                required: true,
                description: "The post ID",
                example: "1"
            ),
        ],
        responses: [
            APIResponse(
                statusCode: 200,
                description: "Successful response",
                schema: "Post",
                example: """
                {
                  "userId": 1,
                  "id": 1,
                  "title": "sunt aut facere repellat",
                  "body": "quia et suscipit..."
                }
                """
            ),
            APIResponse(
                statusCode: 404,
                description: "Post not found",
                schema: "Error",
                example: "{}"
            ),
        ]
    )

    static let createPost = APIEndpoint(
        id: "create-post",
        category: "Posts",
        method: .post,
        path: "/posts",
        summary: "Create a new post",
        description: "Create a new post with the provided data.",
        requestBody: RequestBody(
            schema: "Post",
            example: """
            {
              "title": "My New Post",
              "body": "This is the content of my post.",
              "userId": 1
            }
            """
        ),
        responses: [
            APIResponse(
                statusCode: 201,
                description: "Post created successfully",
                schema: "Post",
                example: """
                {
                  "id": 101,
                  "title": "My New Post",
                  "body": "This is the content of my post.",
                  "userId": 1
                }
                """
            ),
        ]
    )

    static let updatePost = APIEndpoint(
        id: "update-post",
        category: "Posts",
        method: .put,
        path: "/posts/{id}",
        summary: "Update a post",
        description: "Update an existing post with new data.",
        parameters: [
            APIParameter(
                name: "id",
                location: .path,
                type: "integer",
                required: true,
                description: "The post ID",
                example: "1"
            ),
        ],
        requestBody: RequestBody(
            schema: "Post",
            example: """
            {
              "id": 1,
              "title": "Updated Title",
              "body": "Updated content",
              "userId": 1
            }
            """
        ),
        responses: [
            APIResponse(
                statusCode: 200,
                description: "Post updated successfully",
                schema: "Post",
                example: """
                {
                  "id": 1,
                  "title": "Updated Title",
                  "body": "Updated content",
                  "userId": 1
                }
                """
            ),
        ]
    )

    static let deletePost = APIEndpoint(
        id: "delete-post",
        category: "Posts",
        method: .delete,
        path: "/posts/{id}",
        summary: "Delete a post",
        description: "Delete a post by its ID.",
        parameters: [
            APIParameter(
                name: "id",
                location: .path,
                type: "integer",
                required: true,
                description: "The post ID",
                example: "1"
            ),
        ],
        responses: [
            APIResponse(
                statusCode: 200,
                description: "Post deleted successfully",
                schema: "Empty",
                example: "{}"
            ),
        ]
    )
}

// MARK: - Users Endpoints

extension APIEndpoint {
    static let getUsers = APIEndpoint(
        id: "get-users",
        category: "Users",
        method: .get,
        path: "/users",
        summary: "Get all users",
        description: "Retrieve a list of all users.",
        responses: [
            APIResponse(
                statusCode: 200,
                description: "Successful response",
                schema: "Array<User>",
                example: """
                [
                  {
                    "id": 1,
                    "name": "Leanne Graham",
                    "username": "Bret",
                    "email": "Sincere@april.biz"
                  }
                ]
                """
            ),
        ]
    )

    static let getUserById = APIEndpoint(
        id: "get-user-by-id",
        category: "Users",
        method: .get,
        path: "/users/{id}",
        summary: "Get a user by ID",
        description: "Retrieve a specific user by their ID.",
        parameters: [
            APIParameter(
                name: "id",
                location: .path,
                type: "integer",
                required: true,
                description: "The user ID",
                example: "1"
            ),
        ],
        responses: [
            APIResponse(
                statusCode: 200,
                description: "Successful response",
                schema: "User",
                example: """
                {
                  "id": 1,
                  "name": "Leanne Graham",
                  "username": "Bret",
                  "email": "Sincere@april.biz"
                }
                """
            ),
        ]
    )

    static let createUser = APIEndpoint(
        id: "create-user",
        category: "Users",
        method: .post,
        path: "/users",
        summary: "Create a new user",
        description: "Create a new user with the provided data.",
        requestBody: RequestBody(
            schema: "User",
            example: """
            {
              "name": "John Doe",
              "username": "johndoe",
              "email": "john@example.com"
            }
            """
        ),
        responses: [
            APIResponse(
                statusCode: 201,
                description: "User created successfully",
                schema: "User",
                example: """
                {
                  "id": 11,
                  "name": "John Doe",
                  "username": "johndoe",
                  "email": "john@example.com"
                }
                """
            ),
        ]
    )
}

// MARK: - Comments Endpoints

extension APIEndpoint {
    static let getComments = APIEndpoint(
        id: "get-comments",
        category: "Comments",
        method: .get,
        path: "/comments",
        summary: "Get all comments",
        description: "Retrieve a list of all comments.",
        parameters: [
            APIParameter(
                name: "postId",
                location: .query,
                type: "integer",
                description: "Filter comments by post ID",
                example: "1"
            ),
        ],
        responses: [
            APIResponse(
                statusCode: 200,
                description: "Successful response",
                schema: "Array<Comment>",
                example: """
                [
                  {
                    "postId": 1,
                    "id": 1,
                    "name": "id labore ex et...",
                    "email": "Eliseo@gardner.biz",
                    "body": "laudantium enim quasi..."
                  }
                ]
                """
            ),
        ]
    )

    static let getCommentsByPostId = APIEndpoint(
        id: "get-comments-by-post",
        category: "Comments",
        method: .get,
        path: "/posts/{postId}/comments",
        summary: "Get comments for a post",
        description: "Retrieve all comments for a specific post.",
        parameters: [
            APIParameter(
                name: "postId",
                location: .path,
                type: "integer",
                required: true,
                description: "The post ID",
                example: "1"
            ),
        ],
        responses: [
            APIResponse(
                statusCode: 200,
                description: "Successful response",
                schema: "Array<Comment>",
                example: """
                [
                  {
                    "postId": 1,
                    "id": 1,
                    "name": "id labore ex et...",
                    "email": "Eliseo@gardner.biz",
                    "body": "laudantium enim quasi..."
                  }
                ]
                """
            ),
        ]
    )
}

// MARK: - Todos Endpoints

extension APIEndpoint {
    static let getTodos = APIEndpoint(
        id: "get-todos",
        category: "Todos",
        method: .get,
        path: "/todos",
        summary: "Get all todos",
        description: "Retrieve a list of all todos.",
        parameters: [
            APIParameter(
                name: "userId",
                location: .query,
                type: "integer",
                description: "Filter todos by user ID",
                example: "1"
            ),
        ],
        responses: [
            APIResponse(
                statusCode: 200,
                description: "Successful response",
                schema: "Array<Todo>",
                example: """
                [
                  {
                    "userId": 1,
                    "id": 1,
                    "title": "delectus aut autem",
                    "completed": false
                  }
                ]
                """
            ),
        ]
    )

    static let getTodoById = APIEndpoint(
        id: "get-todo-by-id",
        category: "Todos",
        method: .get,
        path: "/todos/{id}",
        summary: "Get a todo by ID",
        description: "Retrieve a specific todo by its ID.",
        parameters: [
            APIParameter(
                name: "id",
                location: .path,
                type: "integer",
                required: true,
                description: "The todo ID",
                example: "1"
            ),
        ],
        responses: [
            APIResponse(
                statusCode: 200,
                description: "Successful response",
                schema: "Todo",
                example: """
                {
                  "userId": 1,
                  "id": 1,
                  "title": "delectus aut autem",
                  "completed": false
                }
                """
            ),
        ]
    )
}

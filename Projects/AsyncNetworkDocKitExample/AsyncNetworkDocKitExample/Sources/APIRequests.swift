//
//  APIRequests.swift
//  AsyncNetworkDocKitExample
//
//  Created by jimmy on 2026/01/01.
//

import AsyncNetworkDocKit

// MARK: - Posts API

@APIRequest(
    response: [Post].self,
    title: "Get all posts",
    description: "JSONPlaceholder에서 모든 포스트를 가져옵니다. 페이지네이션과 필터링을 지원합니다.",
    baseURL: APIConfiguration.jsonPlaceholder,
    path: "/posts",
    method: "get",
    tags: ["Posts", "Read"],
    responseExample: """
    [
      {
        "userId": 1,
        "id": 1,
        "title": "sunt aut facere",
        "body": "quia et suscipit..."
      }
    ]
    """
)
struct GetAllPostsRequest {
    @QueryParameter var userId: Int?
    @QueryParameter var _limit: Int?
}

@APIRequest(
    response: Post.self,
    title: "Get post by ID",
    description: "특정 포스트의 상세 정보를 가져옵니다.",
    baseURL: APIConfiguration.jsonPlaceholder,
    path: "/posts/{id}",
    method: "get",
    tags: ["Posts", "Read"]
)
struct GetPostByIdRequest {
    @PathParameter var id: Int
}

@APIRequest(
    response: Post.self,
    title: "Create a new post",
    description: "새로운 포스트를 생성합니다.",
    baseURL: APIConfiguration.jsonPlaceholder,
    path: "/posts",
    method: "post",
    tags: ["Posts", "Write"],
    requestBodyExample: """
    {
      "title": "My Post Title",
      "body": "This is the post content",
      "userId": 1
    }
    """
)
struct CreatePostRequest {
    @RequestBody var body: PostBody?
}

@APIRequest(
    response: Post.self,
    title: "Update a post",
    description: "기존 포스트를 업데이트합니다.",
    baseURL: APIConfiguration.jsonPlaceholder,
    path: "/posts/{id}",
    method: "put",
    tags: ["Posts", "Write"]
)
struct UpdatePostRequest {
    @PathParameter var id: Int
    @RequestBody var body: PostBody?
}

@APIRequest(
    response: EmptyResponse.self,
    title: "Delete a post",
    description: "포스트를 삭제합니다.",
    baseURL: APIConfiguration.jsonPlaceholder,
    path: "/posts/{id}",
    method: "delete",
    tags: ["Posts", "Write"]
)
struct DeletePostRequest {
    @PathParameter var id: Int
}

// MARK: - Users API

@APIRequest(
    response: [User].self,
    title: "Get all users",
    description: "모든 사용자 목록을 가져옵니다.",
    baseURL: APIConfiguration.jsonPlaceholder,
    path: "/users",
    method: "get",
    tags: ["Users", "Read"]
)
struct GetAllUsersRequest {}

@APIRequest(
    response: User.self,
    title: "Get user by ID",
    description: "특정 사용자의 상세 정보를 가져옵니다.",
    baseURL: APIConfiguration.jsonPlaceholder,
    path: "/users/{id}",
    method: "get",
    tags: ["Users", "Read"]
)
struct GetUserByIdRequest {
    @PathParameter var id: Int
}

@APIRequest(
    response: User.self,
    title: "Create a new user",
    description: "새로운 사용자를 생성합니다.",
    baseURL: APIConfiguration.jsonPlaceholder,
    path: "/users",
    method: "post",
    tags: ["Users", "Write"]
)
struct CreateUserRequest {
    @RequestBody var body: UserBody?
}

// MARK: - Comments API

@APIRequest(
    response: [Comment].self,
    title: "Get post comments",
    description: "특정 포스트의 모든 댓글을 가져옵니다.",
    baseURL: APIConfiguration.jsonPlaceholder,
    path: "/posts/{postId}/comments",
    method: "get",
    tags: ["Comments", "Read"]
)
struct GetPostCommentsRequest {
    @PathParameter var postId: Int
}

@APIRequest(
    response: Comment.self,
    title: "Create a comment",
    description: "새로운 댓글을 작성합니다.",
    baseURL: APIConfiguration.jsonPlaceholder,
    path: "/comments",
    method: "post",
    tags: ["Comments", "Write"]
)
struct CreateCommentRequest {
    @RequestBody var body: CommentBody?
}

// MARK: - Albums API

@APIRequest(
    response: [Album].self,
    title: "Get user albums",
    description: "특정 사용자의 모든 앨범을 가져옵니다.",
    baseURL: APIConfiguration.jsonPlaceholder,
    path: "/users/{userId}/albums",
    method: "get",
    tags: ["Albums", "Read"],
    responseExample: """
    [
      {
        "userId": 1,
        "id": 1,
        "title": "quidem molestiae enim"
      },
      {
        "userId": 1,
        "id": 2,
        "title": "sunt qui excepturi placeat culpa"
      }
    ]
    """
)
struct GetUserAlbumsRequest {
    @PathParameter var userId: Int
}

@APIRequest(
    response: [Photo].self,
    title: "Get album photos",
    description: "특정 앨범의 모든 사진을 가져옵니다.",
    baseURL: APIConfiguration.jsonPlaceholder,
    path: "/albums/{albumId}/photos",
    method: "get",
    tags: ["Albums", "Read"],
    responseExample: """
    [
      {
        "albumId": 1,
        "id": 1,
        "title": "accusamus beatae ad facilis cum similique qui sunt",
        "url": "https://via.placeholder.com/600/92c952",
        "thumbnailUrl": "https://via.placeholder.com/150/92c952"
      }
    ]
    """
)
struct GetAlbumPhotosRequest {
    @PathParameter var albumId: Int
}

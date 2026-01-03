//
//  APIRequests.swift
//  AsyncNetworkDocKitExample
//
//  Created by jimmy on 2026/01/01.
//

import AsyncNetworkDocKit
import Foundation

// MARK: - Base URLs

let jsonPlaceholderURL = "https://jsonplaceholder.typicode.com"
let apiExampleURL = "https://api.example.com"

// MARK: - Posts API

@APIRequest(
    response: [Post].self,
    title: "Get all posts",
    description: "JSONPlaceholder에서 모든 포스트를 가져옵니다. 페이지네이션과 필터링을 지원합니다.",
    baseURL: jsonPlaceholderURL,
    path: "/posts",
    method: .get,
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
    @QueryParameter(key: "_limit") var limit: Int?
}

@APIRequest(
    response: Post.self,
    title: "Get post by ID",
    description: "특정 포스트의 상세 정보를 가져옵니다.",
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .get,
    tags: ["Posts", "Read"]
)
struct GetPostByIdRequest {
    @PathParameter var id: Int
    @HeaderField(key: .userAgent) var userAgent: String? = "AsyncNetworkDocKit/1.0.0"
    @HeaderField(key: .acceptLanguage) var acceptLanguage: String? = "ko-KR,ko;q=0.9,en;q=0.8"
}

@APIRequest(
    response: Post.self,
    title: "Create a new post",
    description: "새로운 포스트를 생성합니다.",
    baseURL: jsonPlaceholderURL,
    path: "/posts",
    method: .post,
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
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    @HeaderField(key: .requestId) var requestId: String? = UUID().uuidString
}

@APIRequest(
    response: Post.self,
    title: "Update a post",
    description: "기존 포스트를 업데이트합니다.",
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .put,
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
    baseURL: jsonPlaceholderURL,
    path: "/posts/{id}",
    method: .delete,
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
    baseURL: jsonPlaceholderURL,
    path: "/users",
    method: .get,
    tags: ["Users", "Read"]
)
struct GetAllUsersRequest {}

@APIRequest(
    response: User.self,
    title: "Get user by ID",
    description: "특정 사용자의 상세 정보를 가져옵니다.",
    baseURL: jsonPlaceholderURL,
    path: "/users/{id}",
    method: .get,
    tags: ["Users", "Read"]
)
struct GetUserByIdRequest {
    @PathParameter var id: Int
    @CustomHeader("X-Client-Version") var clientVersion: String? = "1.0.0"
    @CustomHeader("X-Platform") var platform: String? = "iOS"
}

@APIRequest(
    response: User.self,
    title: "Create a new user",
    description: "새로운 사용자를 생성합니다.",
    baseURL: jsonPlaceholderURL,
    path: "/users",
    method: .post,
    tags: ["Users", "Write"]
)
struct CreateUserRequest {
    @RequestBody var body: UserBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .timestamp) var timestamp: String? = String(Int(Date().timeIntervalSince1970))
}

// MARK: - Comments API

@APIRequest(
    response: [Comment].self,
    title: "Get post comments",
    description: "특정 포스트의 모든 댓글을 가져옵니다.",
    baseURL: jsonPlaceholderURL,
    path: "/posts/{postId}/comments",
    method: .get,
    tags: ["Comments", "Read"]
)
struct GetPostCommentsRequest {
    @PathParameter var postId: Int
}

@APIRequest(
    response: Comment.self,
    title: "Create a comment",
    description: "새로운 댓글을 작성합니다.",
    baseURL: jsonPlaceholderURL,
    path: "/comments",
    method: .post,
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
    baseURL: jsonPlaceholderURL,
    path: "/users/{userId}/albums",
    method: .get,
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
    baseURL: jsonPlaceholderURL,
    path: "/albums/{albumId}/photos",
    method: .get,
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

// MARK: - Complex Order API

@APIRequest(
    response: Order.self,
    title: "Create an order",
    description: "복잡한 주문을 생성합니다. 여러 상품, 배송지, 결제 정보를 포함합니다.",
    baseURL: apiExampleURL,
    path: "/orders",
    method: .post,
    tags: ["Orders", "Write", "Complex"],
    requestBodyExample: """
        {
          "items": [
            {
              "productId": 101,
              "quantity": 2,
              "options": {
                "color": "blue",
                "size": "L"
              }
            },
            {
              "productId": 205,
              "quantity": 1,
              "options": {
                "material": "cotton"
              }
            }
          ],
          "shippingAddress": {
            "recipientName": "홍길동",
            "phoneNumber": "010-1234-5678",
            "street": "테헤란로 123",
            "city": "서울",
            "state": "서울특별시",
            "zipCode": "06234",
            "country": "KR",
            "instructions": "문 앞에 놔주세요"
          },
          "paymentMethod": {
            "type": "card",
            "cardToken": "tok_1234567890abcdef",
            "bankAccountId": null
          },
          "couponCode": "SUMMER2026",
          "giftMessage": "생일 축하해요!",
          "subscribeNewsletter": true
        }
        """,
    responseExample: """
        {
          "id": 9001,
          "userId": 42,
          "orderNumber": "ORD-2026-001234",
          "status": "pending",
          "totalAmount": 89500.50,
          "items": [
            {
              "productId": 101,
              "productName": "Premium T-Shirt",
              "quantity": 2,
              "unitPrice": 29900.00,
              "discount": 2000.00,
              "options": {
                "color": "blue",
                "size": "L"
              }
            },
            {
              "productId": 205,
              "productName": "Cotton Pants",
              "quantity": 1,
              "unitPrice": 45900.00,
              "discount": null,
              "options": {
                "material": "cotton"
              }
            }
          ],
          "shippingAddress": {
            "recipientName": "홍길동",
            "phoneNumber": "010-1234-5678",
            "street": "테헤란로 123",
            "city": "서울",
            "state": "서울특별시",
            "zipCode": "06234",
            "country": "KR",
            "instructions": "문 앞에 놔주세요"
          },
          "paymentMethod": {
            "type": "card",
            "cardLastFour": "1234",
            "cardBrand": "Visa"
          },
          "createdAt": "2026-01-02T10:30:00Z",
          "estimatedDelivery": "2026-01-05T18:00:00Z"
        }
        """
)
struct CreateOrderRequest {
    @RequestBody var body: CreateOrderBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .requestId) var requestId: String? = UUID().uuidString
    @HeaderField(key: .sessionId) var sessionId: String?
    @CustomHeader("X-Idempotency-Key") var idempotencyKey: String? = UUID().uuidString
}

@APIRequest(
    response: Order.self,
    title: "Get order by ID",
    description: "특정 주문의 상세 정보를 조회합니다.",
    baseURL: apiExampleURL,
    path: "/orders/{orderId}",
    method: .get,
    tags: ["Orders", "Read", "Complex"],
    responseExample: """
        {
          "id": 9001,
          "userId": 42,
          "orderNumber": "ORD-2026-001234",
          "status": "shipped",
          "totalAmount": 89500.50,
          "items": [
            {
              "productId": 101,
              "productName": "Premium T-Shirt",
              "quantity": 2,
              "unitPrice": 29900.00,
              "discount": 2000.00,
              "options": {
                "color": "blue",
                "size": "L"
              }
            }
          ],
          "shippingAddress": {
            "recipientName": "홍길동",
            "phoneNumber": "010-1234-5678",
            "street": "테헤란로 123",
            "city": "서울",
            "state": "서울특별시",
            "zipCode": "06234",
            "country": "KR",
            "instructions": "문 앞에 놔주세요"
          },
          "paymentMethod": {
            "type": "card",
            "cardLastFour": "1234",
            "cardBrand": "Visa"
          },
          "createdAt": "2026-01-02T10:30:00Z",
          "estimatedDelivery": "2026-01-05T18:00:00Z"
        }
        """
)
struct GetOrderRequest {
    @PathParameter var orderId: Int
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .userAgent) var userAgent: String? = "AsyncNetworkDocKit/1.0.0"
}

// MARK: - Complex Profile API

@APIRequest(
    response: UserProfile.self,
    title: "Update user profile",
    description: "사용자 프로필을 업데이트합니다. 선호 설정, 소셜 링크 등을 포함합니다.",
    baseURL: apiExampleURL,
    path: "/profile",
    method: .put,
    tags: ["Profile", "Write", "Complex"],
    requestBodyExample: """
        {
          "fullName": "김철수",
          "bio": "Full-stack developer passionate about Swift and iOS",
          "avatar": "https://example.com/avatars/chulsoo.jpg",
          "preferences": {
            "language": "ko",
            "timezone": "Asia/Seoul",
            "theme": "dark",
            "notifications": {
              "email": true,
              "push": true,
              "sms": false,
              "frequency": "daily"
            },
            "privacy": {
              "profileVisibility": "public",
              "showEmail": false,
              "showActivity": true
            }
          },
          "socialLinks": {
            "twitter": "https://twitter.com/chulsoo_kim",
            "github": "https://github.com/chulsoo",
            "linkedin": "https://linkedin.com/in/chulsoo-kim",
            "website": "https://chulsoo.dev"
          }
        }
        """,
    responseExample: """
        {
          "id": 42,
          "username": "chulsoo_kim",
          "email": "chulsoo@example.com",
          "fullName": "김철수",
          "avatar": "https://example.com/avatars/chulsoo.jpg",
          "bio": "Full-stack developer passionate about Swift and iOS",
          "preferences": {
            "language": "ko",
            "timezone": "Asia/Seoul",
            "theme": "dark",
            "notifications": {
              "email": true,
              "push": true,
              "sms": false,
              "frequency": "daily"
            },
            "privacy": {
              "profileVisibility": "public",
              "showEmail": false,
              "showActivity": true
            }
          },
          "socialLinks": {
            "twitter": "https://twitter.com/chulsoo_kim",
            "github": "https://github.com/chulsoo",
            "linkedin": "https://linkedin.com/in/chulsoo-kim",
            "website": "https://chulsoo.dev"
          },
          "stats": {
            "posts": 127,
            "followers": 1542,
            "following": 289,
            "likes": 3891
          },
          "badges": [
            {
              "id": 1,
              "name": "Early Adopter",
              "icon": "🌟",
              "description": "Joined in the first month",
              "earnedAt": "2025-01-15T00:00:00Z"
            },
            {
              "id": 5,
              "name": "Top Contributor",
              "icon": "🏆",
              "description": "Made 100+ contributions",
              "earnedAt": "2025-12-01T00:00:00Z"
            }
          ],
          "isPremium": true,
          "memberSince": "2025-01-15T00:00:00Z"
        }
        """
)
struct UpdateProfileRequest {
    @RequestBody var body: UpdateProfileBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
    @HeaderField(key: .acceptLanguage) var acceptLanguage: String? = "ko-KR,ko;q=0.9"
    @CustomHeader("X-Device-Id") var deviceId: String?
}

// MARK: - Complex Search API

@APIRequest(
    response: SearchResult.self,
    title: "Advanced search",
    description: "고급 검색 필터를 사용하여 컨텐츠를 검색합니다. 다중 필터, 정렬, 페이지네이션을 지원합니다.",
    baseURL: apiExampleURL,
    path: "/search",
    method: .post,
    tags: ["Search", "Complex"],
    requestBodyExample: """
        {
          "query": "iOS development",
          "filters": {
            "categories": ["programming", "mobile"],
            "tags": ["swift", "swiftui", "ios"],
            "authors": [1, 5, 12],
            "dateRange": {
              "from": "2025-01-01",
              "to": "2026-01-31"
            },
            "priceRange": {
              "min": 0.0,
              "max": 50000.0
            },
            "rating": 4,
            "inStock": true
          },
          "sort": {
            "field": "relevance",
            "order": "desc"
          },
          "pagination": {
            "page": 1,
            "pageSize": 20
          }
        }
        """,
    responseExample: """
        {
          "items": [
            {
              "id": 301,
              "type": "course",
              "title": "Advanced iOS Development with SwiftUI",
              "description": "Master SwiftUI and build production-ready iOS apps",
              "thumbnail": "https://example.com/courses/301/thumb.jpg",
              "author": {
                "id": 5,
                "name": "Jane Developer",
                "avatar": "https://example.com/avatars/jane.jpg"
              },
              "tags": ["swift", "swiftui", "ios", "advanced"],
              "createdAt": "2025-11-15T10:00:00Z",
              "score": 98.5
            },
            {
              "id": 412,
              "type": "article",
              "title": "SwiftUI Best Practices in 2026",
              "description": "Learn the latest patterns and techniques",
              "thumbnail": "https://example.com/articles/412/thumb.jpg",
              "author": {
                "id": 12,
                "name": "John Swift",
                "avatar": "https://example.com/avatars/john.jpg"
              },
              "tags": ["swift", "swiftui", "best-practices"],
              "createdAt": "2025-12-20T14:30:00Z",
              "score": 95.2
            }
          ],
          "totalCount": 156,
          "page": 1,
          "pageSize": 20,
          "facets": [
            {
              "name": "category",
              "values": [
                {
                  "value": "programming",
                  "count": 98
                },
                {
                  "value": "mobile",
                  "count": 78
                }
              ]
            },
            {
              "name": "rating",
              "values": [
                {
                  "value": "5",
                  "count": 45
                },
                {
                  "value": "4",
                  "count": 67
                }
              ]
            }
          ]
        }
        """
)
struct SearchRequest {
    @RequestBody var body: SearchFilterBody?
    @HeaderField(key: .authorization) var authorization: String?
    @HeaderField(key: .requestId) var requestId: String? = UUID().uuidString
    @HeaderField(key: .userAgent) var userAgent: String? = "AsyncNetworkDocKit/1.0.0"
    @CustomHeader("X-Search-Session") var searchSession: String? = UUID().uuidString
}

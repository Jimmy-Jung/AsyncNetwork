# OpenAPI Example

AsyncNetwork의 `@APIRequest`, `@TestableDTO`, `@TestableSchemer` 매크로를 사용한 OpenAPI 스펙 생성 예제입니다.

## 📁 파일 구조

```
Examples/OpenAPIExample/
├── README.md           # 이 파일
├── Models.swift        # @TestableDTO가 적용된 데이터 모델
└── APIRequests.swift   # @APIRequest + @TestableSchemer가 적용된 API 정의
```

## 🎯 목적

이 예제는 다음을 보여줍니다:

1. **@TestableDTO**: Codable 모델에 테스트 데이터 생성 및 OpenAPI example 제공
2. **@APIRequest**: RESTful API 엔드포인트 선언적 정의
3. **@TestableSchemer**: API 테스트 시나리오 및 에러 응답 example 정의
4. **ExportOpenAPI.swift**: 소스 코드를 파싱하여 OpenAPI 3.0 스펙 자동 생성

## 🚀 OpenAPI 스펙 생성 방법

### 1. 기본 사용법

```bash
cd /Users/jimmy/Documents/GitHub/AsyncNetwork

# OpenAPI JSON 생성
bash Scripts/OpenAPI/generate-docs.sh \
  --project Examples/OpenAPIExample \
  --output Docs/openapi-example.json \
  --title "OpenAPI Example API" \
  --version "1.0.0" \
  --description "AsyncNetwork 매크로를 사용한 API 문서화 예제"
```

### 2. 고급 사용법

```bash
# 여러 디렉토리를 포함하여 생성
bash Scripts/OpenAPI/generate-docs.sh \
  --project Examples/OpenAPIExample \
  --project Projects/AsyncNetwork/Tests \
  --output Docs/full-api.json \
  --title "Full API Documentation" \
  --version "2.0.0"
```

### 3. Swift 스크립트 직접 실행

```bash
swift Scripts/OpenAPI/ExportOpenAPI.swift \
  --project Examples/OpenAPIExample \
  --output Docs/openapi.json \
  --title "My API" \
  --version "1.0.0" \
  --format json
```

## 📊 생성되는 OpenAPI 스펙 예시

생성된 `openapi.json`은 다음을 포함합니다:

```json
{
  "openapi": "3.0.0",
  "info": {
    "title": "OpenAPI Example API",
    "version": "1.0.0"
  },
  "paths": {
    "/posts/{id}": {
      "get": {
        "summary": "Get post by ID",
        "responses": {
          "200": {
            "description": "Success",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/Post" },
                "example": {
                  "userId": 1,
                  "id": 1,
                  "title": "sunt aut facere",
                  "body": "quia et suscipit"
                }
              }
            }
          },
          "404": {
            "description": "Not Found",
            "content": {
              "application/json": {
                "example": {
                  "error": "Post not found",
                  "code": "POST_NOT_FOUND"
                }
              }
            }
          }
        }
      }
    }
  },
  "components": {
    "schemas": {
      "Post": {
        "type": "object",
        "properties": {
          "userId": { "type": "integer" },
          "id": { "type": "integer" },
          "title": { "type": "string" },
          "body": { "type": "string" }
        },
        "example": {
          "userId": 1,
          "id": 1,
          "title": "sunt aut facere",
          "body": "quia et suscipit"
        }
      }
    }
  }
}
```

## 🎨 매크로 사용 예시

### @TestableDTO

```swift
@TestableDTO(
    fixtureJSON: """
    {
      "id": 1,
      "title": "Example Post",
      "body": "This is an example"
    }
    """
)
struct Post: Codable {
    let id: Int
    let title: String
    let body: String
}

// 자동 생성된 메서드들
let mock = Post.mock()        // 랜덤 테스트 데이터
let fixture = Post.fixture()  // fixtureJSON 기반 고정 데이터
let array = Post.mockArray(count: 10)
try post.assertValid()        // 자동 검증
```

### @APIRequest + @TestableSchemer

```swift
@APIRequest(
    response: Post.self,
    title: "Get post",
    baseURL: "https://api.example.com",
    path: "/posts/{id}",
    method: .get,
    tags: ["Posts"]
)
@TestableSchemer(
    errorExamples: [
        "404": """{"error": "Not found"}""",
        "500": """{"error": "Server error"}"""
    ]
)
struct GetPostRequest {
    @PathParameter var id: Int
}

// 자동 생성된 테스트 헬퍼
let (data, response, error) = GetPostRequest.mockResponse(for: .success)
let (_, _, error) = GetPostRequest.mockResponse(for: .notFound)
```

## 📖 API 목록

### Posts API
- `GET /posts` - 모든 포스트 조회
- `GET /posts/{id}` - 특정 포스트 조회
- `POST /posts` - 포스트 생성
- `PUT /posts/{id}` - 포스트 수정
- `DELETE /posts/{id}` - 포스트 삭제

### Users API
- `GET /users` - 모든 사용자 조회
- `GET /users/{id}` - 특정 사용자 조회
- `POST /users` - 사용자 생성

### Comments API
- `GET /posts/{postId}/comments` - 포스트의 댓글 조회
- `POST /comments` - 댓글 작성

### Albums API
- `GET /users/{userId}/albums` - 사용자의 앨범 조회
- `GET /albums/{albumId}/photos` - 앨범의 사진 조회

### Complex APIs
- `POST /orders` - 복잡한 주문 생성
- `GET /orders/{orderId}` - 주문 조회

## 🔧 커스터마이징

### fixtureJSON 수정

`Models.swift`에서 각 DTO의 `fixtureJSON`을 수정하면 OpenAPI example이 자동으로 업데이트됩니다.

### 에러 응답 추가

`APIRequests.swift`에서 `@TestableSchemer`의 `errorExamples`를 수정하여 에러 응답을 추가할 수 있습니다.

```swift
@TestableSchemer(
    errorExamples: [
        "400": """{"error": "Bad request"}""",
        "401": """{"error": "Unauthorized"}""",
        "403": """{"error": "Forbidden"}""",
        "404": """{"error": "Not found"}""",
        "500": """{"error": "Server error"}"""
    ]
)
```

## 🎯 다음 단계

1. 생성된 `openapi.json`을 [Swagger Editor](https://editor.swagger.io/)에서 열어보기
2. [Postman](https://www.postman.com/)에 import하여 API 테스트
3. 프로덕션 API 서버에 배포하여 실제 문서로 활용

## 📚 참고 자료

- [AsyncNetwork README](../../README.md)
- [OpenAPI 3.0 Specification](https://swagger.io/specification/)
- [Swift Macros Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/)


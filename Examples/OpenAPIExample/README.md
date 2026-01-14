# OpenAPI Example

AsyncNetwork의 `@APIRequest`, `@APIDocument`, `@APITestable`, `@ResponseDocument` 매크로를 사용한 OpenAPI 스펙 생성 예제입니다.

## 📁 파일 구조

```
Examples/OpenAPIExample/
├── README.md           # 이 파일
├── Models.swift        # @ResponseDocument가 적용된 데이터 모델
├── ErrorModels.swift   # @ResponseDocument가 적용된 에러 모델
└── APIRequests.swift   # @APIRequest + @APIDocument + @APITestable이 적용된 API 정의
```

## 🎯 목적

이 예제는 다음을 보여줍니다:

1. **@ResponseDocument**: Codable 모델에 OpenAPI example 제공
2. **@APIRequest**: RESTful API 엔드포인트 선언적 정의
3. **@APIDocument**: API 문서화 메타데이터 (title, description, tags)
4. **@APITestable**: API 테스트 시나리오 및 에러 응답 example 정의
5. **ExportOpenAPI.swift**: 소스 코드를 파싱하여 OpenAPI 3.0 스펙 자동 생성

## 🚀 OpenAPI 스펙 생성 방법

### 1. 기본 사용법

```bash
cd /Users/jimmy/Documents/GitHub/AsyncNetwork

# OpenAPI JSON 생성
bash Scripts/OpenAPI/generate-docs.sh \
  --project Examples/OpenAPIExample \
  --output docs/openapi-example.json \
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
  --output docs/full-api.json \
  --title "Full API Documentation" \
  --version "2.0.0"
```

### 3. Swift 스크립트 직접 실행

```bash
swift Scripts/OpenAPI/ExportOpenAPI.swift \
  --project Examples/OpenAPIExample \
  --output docs/openapi.json \
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
        "description": "특정 포스트의 상세 정보를 가져옵니다...",
        "tags": ["Posts"],
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

### 분리된 매크로 구조

AsyncNetwork는 역할별로 분리된 매크로를 제공합니다:

#### @APIRequest (필수)
API 엔드포인트의 핵심 정보를 정의합니다.

```swift
@APIRequest(
    response: Post.self,
    baseURL: "https://api.example.com",
    path: "/posts/{id}",
    method: .get,
    errorResponses: [
        404: NotFoundError.self
    ]
)
```

#### @APIDocument (선택)
API 문서화를 위한 메타데이터를 추가합니다.

```swift
@APIDocument(
    title: "Get post by ID",
    description: """
    특정 포스트의 상세 정보를 가져옵니다.
    
    파라미터:
    • id: Post의 고유 식별자
    """,
    tags: ["Posts"]
)
```

#### @APITestable (선택)
테스트 시나리오와 에러 예제를 정의합니다.

```swift
@APITestable(
    scenarios: [.success, .notFound, .serverError],
    errorExamples: [
        "404": """
        {
          "error": "Post not found",
          "code": "POST_NOT_FOUND"
        }
        """
    ]
)
```

#### 전체 예제

```swift
@APIRequest(
    response: Post.self,
    baseURL: "https://api.example.com",
    path: "/posts/{id}",
    method: .get,
    errorResponses: [
        404: NotFoundError.self
    ]
)
@APIDocument(
    title: "Get post by ID",
    description: "특정 포스트의 상세 정보를 가져옵니다.",
    tags: ["Posts"]
)
@APITestable(
    scenarios: [.success, .notFound],
    errorExamples: [
        "404": """{"error": "Not found"}"""
    ]
)
struct GetPostByIdRequest {
    @PathParameter var id: Int
    
    init(id: Int) {
        self.id = id
    }
}
```

### @ResponseDocument

Codable 모델에 OpenAPI example을 제공합니다.

```swift
@ResponseDocument(
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

`APIRequests.swift`에서 `@APITestable`의 `errorExamples`를 수정하여 에러 응답을 추가할 수 있습니다.

```swift
@APITestable(
    scenarios: [.success, .clientError, .unauthorized],
    errorExamples: [
        "400": """{"error": "Bad request"}""",
        "401": """{"error": "Unauthorized"}""",
        "403": """{"error": "Forbidden"}""",
        "404": """{"error": "Not found"}""",
        "500": """{"error": "Server error"}"""
    ]
)
```

### 에러 타입 매핑

`@APIRequest`의 `errorResponses`로 HTTP 상태 코드와 에러 타입을 매핑할 수 있습니다.

```swift
@APIRequest(
    response: Post.self,
    baseURL: "https://api.example.com",
    path: "/posts/{id}",
    method: .get,
    errorResponses: [
        404: NotFoundError.self,
        500: ServerError.self
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


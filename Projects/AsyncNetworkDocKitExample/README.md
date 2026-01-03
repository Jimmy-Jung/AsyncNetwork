# AsyncNetworkDocKitExample

**AsyncNetworkDocKit**을 활용한 Redoc 스타일 3열 레이아웃 API 문서 앱 데모입니다.

## 📱 스크린샷

```
┌─────────────────────────────────────────────────────────────────────┐
│               JSONPlaceholder API Docs                              │
├──────────────┬──────────────────────────────┬──────────────────────┤
│  1열: 리스트  │     2열: API 상세 설명        │   3열: 실시간 테스터  │
├──────────────┼──────────────────────────────┼──────────────────────┤
│ 🔍 Search   │                              │   🎯 Try It Out      │
│             │   📄 GET /posts               │                      │
│ 📁 Posts    │   Get all posts               │   ⚙️ Parameters     │
│   GET /posts│                               │   userId: [ 1    ]   │
│   GET /{id} │   📝 Description:             │   _limit: [ 10   ]   │
│   POST...   │   JSONPlaceholder에서 모든     │                      │
│   PUT...    │   포스트를 가져옵니다          │   📤 Send Request    │
│   DELETE... │                               │                      │
│             │   📋 Parameters:              │   ✅ Response        │
│ 📁 Users    │   • userId (query, optional)  │   Status: 200        │
│   GET /users│   • _limit (query, optional)  │   [                  │
│   GET /{id} │                               │     {                │
│   POST...   │   📥 Response: [Post]         │       "userId": 1,   │
│             │   [                           │       "id": 1,       │
│ 📁 Comments │     {                         │       ...            │
│   GET...    │       "userId": 1,            │     }                │
│   POST...   │       "id": 1,                │   ]                  │
│             │       ...                     │                      │
│ 📁 Albums   │     }                         │                      │
│   GET...    │   ]                           │                      │
└──────────────┴──────────────────────────────┴──────────────────────┘
```

## ✨ 주요 기능

### 3열 레이아웃 (Redoc 스타일)

#### 1열: API 리스트
- 카테고리별 API 그룹화
- 검색 기능 (API 경로, 타이틀)
- HTTP 메서드 뱃지 (GET/POST/PUT/DELETE)
- Sidebar 스타일 리스트

#### 2열: API 상세 설명
- HTTP 메서드 및 엔드포인트 경로
- API 설명
- 파라미터 정보 (Query, Path, Body)
- Request Body 예시
- Response 타입 및 예시
- **토글 가능한 Response Structure**: 중첩된 타입(OrderItem, ShippingAddress 등)을 클릭하여 펼치거나 접을 수 있음

#### 3열: 실시간 API 테스터
- 파라미터 입력 필드 (자동으로 예시값 채워짐)
- Request Body 편집기
- Send Request 버튼
- 실시간 응답 표시 (JSON Pretty Print)
- HTTP 상태 코드 표시
- 에러 메시지 표시

### API 카테고리
- **Posts**: 포스트 CRUD 작업 (5개 엔드포인트)
- **Users**: 사용자 관리 (3개 엔드포인트)
- **Comments**: 댓글 관리 (2개 엔드포인트)
- **Albums**: 앨범 및 사진 관리 (2개 엔드포인트)

## 📋 포함된 API 엔드포인트

### Posts API
```swift
GET    /posts           - 모든 포스트 조회
GET    /posts/{id}      - 특정 포스트 조회
POST   /posts           - 새 포스트 생성
PUT    /posts/{id}      - 포스트 업데이트
DELETE /posts/{id}      - 포스트 삭제
```

### Users API
```swift
GET    /users           - 모든 사용자 조회
GET    /users/{id}      - 특정 사용자 조회
POST   /users           - 새 사용자 생성
```

### Comments API
```swift
GET    /posts/{postId}/comments  - 포스트 댓글 조회
POST   /comments                 - 새 댓글 생성
```

### Albums API
```swift
GET    /users/{userId}/albums    - 사용자 앨범 조회
GET    /albums/{albumId}/photos  - 앨범 사진 조회
```

## 🏗 프로젝트 구조

```
AsyncNetworkDocKitExample/
├── Project.swift
└── AsyncNetworkDocKitExample/
    ├── Sources/
    │   ├── AsyncNetworkDocKitExampleApp.swift  # DocKitFactory 사용
    │   ├── APIRequests.swift                   # @APIRequest 정의
    │   └── Models.swift                        # Response 모델
    └── Resources/
        └── Assets.xcassets/
```

## 🚀 실행 방법

### 1. Tuist를 사용하는 경우

```bash
# 1. Tuist 의존성 설치
tuist install

# 2. 프로젝트 생성
tuist generate

# 3. Xcode에서 열기
open AsyncNetwork.xcworkspace

# 4. AsyncNetworkDocKitExample 스킴 선택 후 실행
```

### 2. 개발 중 변경사항 확인

```bash
# 변경 후 재생성
tuist generate

# 또는 watch 모드
tuist generate --watch
```

## 💡 코드 구조 설명

### 1. App 진입점

```swift
@main
struct AsyncNetworkDocKitExampleApp: App {
    let networkService = NetworkService()
    
    var body: some Scene {
        DocKitFactory.createDocApp(
            endpoints: [
                "Posts": [
                    GetAllPostsRequest.metadata,
                    GetPostByIdRequest.metadata,
                    // ...
                ],
                "Users": [...],
                // ...
            ],
            networkService: networkService,
            appTitle: "JSONPlaceholder API Docs"
        )
    }
}
```

> ✨ **자동 타입 등록**: 모든 Response 타입과 RequestBody 타입에 `@DocumentedType`를 적용하면, `metadata` 접근 시 자동으로 해당 타입과 중첩 타입들이 `TypeRegistry`에 등록됩니다. 수동 등록 코드(`registerAllDocumentedTypes()`)는 더 이상 필요하지 않습니다!
>
> **작동 원리:**
> 1. `@APIRequest` 매크로가 `metadata` 프로퍼티를 생성할 때, Response/RequestBody 타입의 `typeStructure`를 참조합니다
> 2. `@DocumentedType` 매크로가 `typeStructure` 접근 시 자기 자신과 중첩 타입들을 자동으로 등록합니다
> 3. 결과적으로 앱 실행 시 `metadata`만 참조하면 모든 타입이 자동 등록됩니다

### 2. API Request 정의

```swift
@APIRequest(
    response: [Post].self,
    title: "Get all posts",
    description: "JSONPlaceholder에서 모든 포스트를 가져옵니다.",
    baseURL: "https://jsonplaceholder.typicode.com",
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
```

### 3. 매크로가 자동 생성

```swift
extension GetAllPostsRequest {
    static var metadata: EndpointMetadata {
        EndpointMetadata(
            id: "GetAllPostsRequest",
            title: "Get all posts",
            description: "JSONPlaceholder에서 모든 포스트를 가져옵니다.",
            method: "get",
            path: "/posts",
            baseURLString: "https://jsonplaceholder.typicode.com",
            // ... 나머지 메타데이터
        )
    }
}
```

## 🎯 사용 목적

이 데모 앱은 다음과 같은 상황에 유용합니다:

1. **API 문서화**: 백엔드 API를 iOS 앱으로 시각화하여 문서화
2. **팀 협업**: API 스펙을 팀원들과 공유하고 실시간으로 테스트
3. **API 테스트**: 실제 API 호출 및 응답을 즉시 확인
4. **클라이언트 개발**: 앱 개발 전 API 구조 미리 파악 및 검증
5. **디버깅**: API 요청/응답 문제를 빠르게 진단

## 🔗 관련 프로젝트

- [AsyncNetwork](../../AsyncNetwork) - 핵심 네트워크 라이브러리
- [AsyncNetworkMacros](../../AsyncNetworkMacros) - `@APIRequest` 매크로
- [AsyncNetworkDocKit](../../AsyncNetworkDocKit) - 문서 앱 UI 라이브러리
- [AsyncNetworkExample](../../AsyncNetworkExample) - AsyncNetwork 기능 데모

## 📝 참고 사항

- 이 앱은 [JSONPlaceholder](https://jsonplaceholder.typicode.com)의 Fake API를 사용합니다
- 실제 데이터 변경은 이루어지지 않습니다 (Mock 응답)
- 모든 API 호출은 실제로 작동하며, 응답을 확인할 수 있습니다

## 🎨 UI/UX 특징

- **Redoc 3열 레이아웃**: 전문적인 API 문서 UI
- **실시간 API 테스터**: 파라미터 입력 후 즉시 요청 가능
- **다크모드 지원**: 자동 라이트/다크 테마 전환
- **반응형 레이아웃**: iPad에서 3열 모두 표시, iPhone에서는 적응형 레이아웃
- **검색 기능**: 빠른 API 검색
- **상태 코드 표시**: HTTP 응답 코드를 색상으로 구분 (200대: 초록, 400대: 주황, 500대: 빨강)


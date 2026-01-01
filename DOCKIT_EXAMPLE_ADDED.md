# AsyncNetworkDocKitExample 데모 앱 추가 완료 ✅

## 📱 새로 추가된 프로젝트

**AsyncNetworkDocKitExample**는 `AsyncNetworkDocKit`를 활용하여 Redoc 스타일의 API 문서 앱을 만드는 방법을 보여주는 데모입니다.

---

## 🎯 주요 특징

### 1. JSONPlaceholder API 문서화
- **12개 엔드포인트** 완전 문서화
- **4개 카테고리**: Posts, Users, Comments, Albums
- 실제 동작하는 API 호출 (JSONPlaceholder Mock API)

### 2. Redoc 스타일 UI
```
┌─────────────────────────────────────────────┐
│      JSONPlaceholder API Docs               │
├──────────────┬──────────────────────────────┤
│ 🔍 Search   │   📄 GET /posts               │
│             │   Get all posts               │
│ 📁 Posts    │                               │
│   GET       │   Description:                │
│   POST      │   JSONPlaceholder에서 모든     │
│   PUT       │   포스트를 가져옵니다          │
│   DELETE    │                               │
│             │   Parameters:                 │
│ 📁 Users    │   • userId (query)            │
│ 📁 Comments │   • _limit (query)            │
│ 📁 Albums   │                               │
└──────────────┴──────────────────────────────┘
```

### 3. 주요 컴포넌트

#### AsyncNetworkDocKitExampleApp.swift
```swift
@main
struct AsyncNetworkDocKitExampleApp: App {
    let networkService = NetworkService()
    
    var body: some Scene {
        DocKitFactory.createDocApp(
            endpoints: [
                "Posts": [
                    GetAllPostsRequest.metadata,
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

#### APIRequests.swift
- `@APIRequest` 매크로 사용
- Property Wrappers (`@QueryParameter`, `@PathParameter`, `@RequestBody`)
- 자동 메타데이터 생성

#### Models.swift
- Codable & Sendable 준수
- JSONPlaceholder 응답 타입들

---

## 🚀 실행 방법

```bash
# 1. 워크스페이스 생성
cd /Users/jimmy/Documents/GitHub/AsyncNetwork
tuist install
tuist generate

# 2. Xcode에서 열기
open AsyncNetwork.xcworkspace

# 3. AsyncNetworkDocKitExample 스킴 선택 후 실행
```

---

## 📁 프로젝트 구조

```
AsyncNetworkDocKitExample/
├── Project.swift                              # Tuist 매니페스트
├── README.md
└── AsyncNetworkDocKitExample/
    ├── Sources/
    │   ├── AsyncNetworkDocKitExampleApp.swift # App 진입점
    │   ├── APIRequests.swift                  # @APIRequest 정의
    │   └── Models.swift                       # Response 모델
    └── Resources/
        └── Assets.xcassets/
```

---

## ✨ 포함된 API 엔드포인트

### Posts (5개)
- `GET /posts` - 모든 포스트 조회
- `GET /posts/{id}` - 특정 포스트 조회
- `POST /posts` - 새 포스트 생성
- `PUT /posts/{id}` - 포스트 업데이트
- `DELETE /posts/{id}` - 포스트 삭제

### Users (3개)
- `GET /users` - 모든 사용자 조회
- `GET /users/{id}` - 특정 사용자 조회
- `POST /users` - 새 사용자 생성

### Comments (2개)
- `GET /posts/{postId}/comments` - 포스트 댓글 조회
- `POST /comments` - 새 댓글 생성

### Albums (2개)
- `GET /users/{userId}/albums` - 사용자 앨범 조회
- `GET /albums/{albumId}/photos` - 앨범 사진 조회

---

## 🎨 UI 기능

### 검색
- API 경로 검색
- 타이틀 검색
- 실시간 필터링

### HTTP 메서드 뱃지
- **GET**: 파란색
- **POST**: 초록색
- **PUT**: 주황색
- **DELETE**: 빨간색

### 상세 문서
- 엔드포인트 경로
- 설명
- 파라미터 정보
- 요청/응답 예시
- 응답 타입

---

## 💡 사용 예시

### @APIRequest 매크로 활용

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

### 자동 생성되는 메타데이터

```swift
extension GetAllPostsRequest {
    static var metadata: EndpointMetadata {
        // 매크로가 자동으로 생성
    }
}
```

---

## 🔗 관련 프로젝트

- **AsyncNetwork**: 핵심 네트워크 라이브러리
- **AsyncNetworkMacros**: `@APIRequest` 매크로
- **AsyncNetworkDocKit**: 문서 앱 UI 라이브러리
- **AsyncNetworkExample**: AsyncNetwork 기능 데모

---

## 📊 Workspace 구조

```
AsyncNetwork.xcworkspace
├── AsyncNetwork (Framework)
├── AsyncNetworkDocKit (Framework)
├── AsyncNetworkExample (App - 기능 데모)
└── AsyncNetworkDocKitExample (App - API 문서) ✨ 새로 추가!
```

---

## ✅ 빌드 확인

```bash
✔ Success
  - AsyncNetwork 빌드 성공
  - AsyncNetworkDocKit 빌드 성공
  - AsyncNetworkDocKitExample 빌드 성공
```

---

## 🎯 활용 방법

이 데모 앱을 참고하여:

1. **자신의 API 문서 앱 생성**
   ```bash
   tuist scaffold api-doc-app --name MyAPIDoc
   ```

2. **@APIRequest 정의**
   - Property Wrappers 활용
   - 메타데이터 작성

3. **DocKitFactory.createDocApp 호출**
   - 카테고리별 엔드포인트 전달
   - NetworkService 설정

4. **자동으로 생성되는 Redoc 스타일 문서 앱 확인!**

---

## 📝 참고

- JSONPlaceholder는 테스트용 Fake REST API입니다
- 실제 데이터 변경은 이루어지지 않습니다
- 모든 API 호출은 정상 작동하며 응답을 확인할 수 있습니다

---

완료! 🎉


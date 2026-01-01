# AsyncNetwork

Swift Concurrency 기반의 타입 안전한 네트워킹 라이브러리

---

## 🎮 빠른 시작 (Tuist Workspace)

```bash
# 1. 저장소 클론
git clone https://github.com/your-repo/AsyncNetwork.git
cd AsyncNetwork

# 2. Dependencies 설치 및 Workspace 생성
tuist install
tuist generate

# 3. Xcode에서 열기
open AsyncNetwork.xcworkspace
```

데모 앱(`AsyncNetworkExample`)이 포함된 워크스페이스가 생성됩니다!

---

## ✨ 주요 기능

- 🎯 **매크로 기반 API 정의**: `@APIRequest` 매크로로 보일러플레이트 제거
- 🔌 **Property Wrappers**: 선언적 파라미터 정의
- 🔄 **Swift Concurrency**: async/await 완전 지원
- 📝 **타입 안전성**: 컴파일 타임 타입 체크
- 🧪 **테스트 가능**: 완전한 단위 테스트 지원 (298개 테스트 통과)
- 📱 **Tuist 템플릿**: API 문서 앱 자동 생성

## 📦 설치

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/AsyncNetwork.git", from: "1.0.0")
]
```

### CocoaPods

```ruby
pod 'AsyncNetwork', '~> 1.0'
```

## 🎮 데모 앱 실행 (Tuist Workspace)

AsyncNetworkExample 데모 앱을 실행하려면:

```bash
# 1. Dependencies 설치
tuist install

# 2. Workspace 생성
tuist generate

# 3. Xcode에서 열기
open AsyncNetwork.xcworkspace
```

생성된 workspace에는 다음이 포함됩니다:
- AsyncNetworkExample (메인 데모 앱)
- AsyncNetwork (로컬 패키지)
- AsyncViewModel, TraceKit (외부 의존성)

## 🚀 빠른 시작

### 1. API 요청 정의

```swift
import AsyncNetwork
import AsyncNetworkMacros

@APIRequest(
    response: [Post].self,
    title: "Get all posts",
    baseURL: "https://jsonplaceholder.typicode.com",
    path: "/posts",
    method: "get",
    tags: ["Posts"]
)
struct GetPostsRequest {
    @QueryParameter var userId: Int?
}
```

### 2. 요청 실행

```swift
let networkService = NetworkService()
let request = GetPostsRequest(userId: 1)
let posts = try await networkService.request(request)
```

## 📖 상세 가이드

### Property Wrappers

#### @QueryParameter
URL 쿼리 파라미터 자동 추가

```swift
@APIRequest(...)
struct GetUsersRequest {
    @QueryParameter var page: Int?
    @QueryParameter var limit: Int?
}
// 결과: /users?page=1&limit=10
```

#### @PathParameter
URL 경로 플레이스홀더 치환

```swift
@APIRequest(path: "/posts/{id}", ...)
struct GetPostRequest {
    @PathParameter var id: Int
}
// /posts/{id} → /posts/123
```

#### @RequestBody
JSON 요청 본문 자동 인코딩

```swift
@APIRequest(method: "post", ...)
struct CreatePostRequest {
    @RequestBody var body: PostBody
}
```

#### @HeaderField
타입 안전한 HTTP 헤더

```swift
@APIRequest(...)
struct AuthenticatedRequest {
    @HeaderField(.authorization) var auth: String?
    @HeaderField(.contentType) var contentType: String?
}
```

#### @CustomHeader
커스텀 헤더 정의

```swift
@APIRequest(...)
struct CustomRequest {
    @CustomHeader("X-API-Key") var apiKey: String?
}
```

### 동적 Base URL

Environment별로 다른 Base URL 사용:

```swift
enum Environment {
    case dev, staging, production
    var baseURL: String {
        switch self {
        case .dev: return "http://localhost:3000"
        case .staging: return "https://staging.api.com"
        case .production: return "https://api.com"
        }
    }
}

@APIRequest(
    response: [Post].self,
    path: "/posts",
    method: "get"
)
struct GetPostsRequest {
    let environment: Environment
    
    var baseURLString: String {
        environment.baseURL
    }
}
```

## 🎨 Tuist 템플릿

API 문서 앱 자동 생성:

```bash
tuist scaffold api-doc-app --name MyAPIDoc
```

## 📱 Example Apps

AsyncNetwork의 기능을 확인할 수 있는 두 가지 데모 앱이 제공됩니다:

### 1. AsyncNetworkExample
AsyncNetwork의 핵심 기능들을 시연하는 인터랙티브 데모 앱:
- 기본 HTTP 메서드 (GET, POST, PUT, DELETE)
- Query/Path Parameters
- Headers & Dynamic BaseURL
- Error Handling & Interceptors
- Request Logging & Live Testing

### 2. AsyncNetworkDocKitExample
Redoc 스타일의 API 문서 앱 (AsyncNetworkDocKit 활용):
- JSONPlaceholder API 12개 엔드포인트 문서화
- 카테고리별 API 그룹화 (Posts, Users, Comments, Albums)
- 검색 기능 및 상세 문서 제공
- HTTP 메서드 뱃지와 파라미터 정보

```bash
# Tuist 워크스페이스 생성
tuist install
tuist generate

# AsyncNetwork.xcworkspace 열기
open AsyncNetwork.xcworkspace

# 실행할 스킴 선택:
# - AsyncNetworkExample (기능 데모)
# - AsyncNetworkDocKitExample (API 문서)
```

생성되는 프로젝트 구조:
```
MyAPIDoc/
├── Project.swift
├── Sources/
│   ├── MyAPIDocApp.swift    # SwiftUI App
│   ├── APIRequests.swift    # @APIRequest 정의
│   └── Models.swift         # 데이터 모델
├── Resources/
│   └── Info.plist
└── README.md
```

## 🧪 테스트

```bash
swift test
```

- ✅ 298개 테스트 통과
- ✅ AsyncNetwork: 284개
- ✅ AsyncNetworkMacros: 14개

### 테스트 커버리지

- API 요청/응답 처리
- 매크로 확장 검증
- Property Wrapper 동작
- 에러 핸들링
- 재시도 로직
- 네트워크 인터셉터

## 📚 예시

데모 앱에서 다양한 예시를 확인할 수 있습니다 (`Projects/AsyncNetworkExample`):

**기본 예시**:
1. Simple GET - 기본 GET 요청
2. Query Parameters - URL 쿼리 파라미터
3. Path Parameters - 동적 경로 파라미터

**HTTP 메서드**:
4. POST Request - 데이터 생성
5. PUT Request - 데이터 수정
6. DELETE Request - 데이터 삭제

**고급 기능**:
7. Headers - 커스텀 헤더 관리
8. Dynamic BaseURL - 환경별 URL
9. Error Handling - 에러 처리
10. Interceptors - 요청/응답 인터셉터

**실시간 테스트**:
11. Live Request Tester - 수동 API 테스트
12. Request Logger - 네트워크 로그

## 🏗 프로젝트 구조

```
AsyncNetwork/
├── Package.swift              # SPM 패키지 정의
├── Workspace.swift            # Tuist Workspace
├── Tuist.swift                # Tuist 전역 설정
├── Tuist/
│   └── Package.swift          # 외부 의존성 (AsyncViewModel, TraceKit)
├── Projects/
│   ├── AsyncNetwork/          # 메인 라이브러리 (SPM으로 관리)
│   ├── AsyncNetworkMacros/    # 매크로 (SPM으로 관리)
│   └── AsyncNetworkExample/   # 데모 앱 (Tuist로 관리)
│       ├── Project.swift
│       └── AsyncNetworkExample/
│           ├── Sources/
│           │   ├── AsyncNetworkExampleApp.swift
│           │   ├── MainMenuView.swift
│           │   └── Features/  # 12가지 예시 뷰
│           └── Resources/
└── Tests/                     # 단위 테스트
```

## 🏗 아키텍처

```
AsyncNetwork
├── Core
│   ├── APIRequest Protocol
│   ├── NetworkService
│   └── HTTPClient
├── PropertyWrappers
│   ├── @QueryParameter
│   ├── @PathParameter
│   ├── @RequestBody
│   └── @HeaderField
├── Macros
│   └── @APIRequest
└── Utilities
    ├── HTTPHeaders
    ├── ErrorMapper
    └── RetryPolicy
```

## 🔧 고급 기능

### 네트워크 인터셉터

```swift
let interceptor = ConsoleLoggingInterceptor(logLevel: .debug)
let config = NetworkConfiguration(interceptors: [interceptor])
let service = NetworkService(configuration: config)
```

### 재시도 정책

```swift
let retryPolicy = RetryPolicy(maxAttempts: 3, delay: 2.0)
let config = NetworkConfiguration(retryPolicy: retryPolicy)
```

### 에러 핸들링

```swift
do {
    let posts = try await networkService.request(request)
} catch let error as NetworkError {
    switch error {
    case .serverError(let statusCode):
        print("Server error: \(statusCode)")
    case .decodingError(let context):
        print("Decoding failed: \(context)")
    case .networkError(let underlying):
        print("Network error: \(underlying)")
    default:
        break
    }
}
```

## 📋 요구사항

- iOS 13.0+ / macOS 10.15+
- Swift 6.0+
- Xcode 15.0+

## 🤝 기여

Pull Request를 환영합니다!

1. Fork the project
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 라이선스

MIT License

## 🙏 감사

- [AsyncViewModel](https://github.com/your-repo/AsyncViewModel) - 매크로 아키텍처 참고

---

Made with ❤️ by AsyncNetwork Team

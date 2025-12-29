# NetworkKit

순수 Foundation 기반의 Swift 네트워크 라이브러리

## 프로젝트 구조

```
NetworkKit/                                   # 루트 (SPM 패키지)
├── Package.swift                             # NetworkKit SPM 정의
├── Projects/
│   ├── NetworkKit/                           # NetworkKit 코어 라이브러리
│   │   ├── Sources/                          # NetworkKit 소스
│   │   │   ├── Core/                         # 핵심 타입
│   │   │   │   ├── APIRequest.swift          # API 요청 프로토콜
│   │   │   │   ├── HTTPMethod.swift          # HTTP 메서드
│   │   │   │   ├── HTTPTask.swift            # 요청 Task
│   │   │   │   ├── HTTPHeaders.swift         # 헤더 빌더
│   │   │   │   ├── HTTPResponse.swift        # HTTP 응답
│   │   │   │   ├── NetworkConfiguration.swift # 네트워크 설정
│   │   │   │   ├── NetworkLogger.swift       # 로거 프로토콜
│   │   │   │   ├── RetryRule.swift           # 재시도 규칙
│   │   │   │   ├── ServerResponse.swift      # 서버 응답 타입
│   │   │   │   ├── RequestInterceptor.swift  # 요청 인터셉터
│   │   │   │   └── AsyncDelayer.swift        # 비동기 지연
│   │   │   ├── Infrastructure/               # 인프라 계층
│   │   │   │   ├── HTTPClient.swift          # URLSession 클라이언트
│   │   │   │   ├── StatusCodeValidator.swift # 상태 코드 검증
│   │   │   │   └── ResponseDecoder.swift     # 응답 디코더
│   │   │   ├── Application/                  # 애플리케이션 계층
│   │   │   │   ├── ErrorMapper.swift         # 에러 매핑
│   │   │   │   └── RetryPolicy.swift         # 재시도 정책
│   │   │   ├── Orchestration/                # 오케스트레이션 계층
│   │   │   │   ├── NetworkService.swift      # 네트워크 서비스
│   │   │   │   ├── ResponseProcessor.swift   # 응답 처리기 (CoR)
│   │   │   │   └── ResponseProcessorStep.swift # 처리 단계
│   │   │   └── NetworkKit.swift              # Factory 함수
│   │   └── Tests/                            # NetworkKit 테스트
│   │       ├── HTTPClientTests.swift
│   │       ├── NetworkServiceTests.swift
│   │       ├── RetryPolicyTests.swift
│   │       └── ...
│   └── NetworkKitExample/                    # Example 앱 (Tuist)
│       ├── Tuist.swift                       # Tuist 전역 설정
│       ├── Project.swift                     # Tuist 프로젝트 정의
│       ├── Tuist/
│       │   ├── Package.swift                 # 의존성 관리 (AsyncViewModel, TraceKit)
│       │   └── ProjectDescriptionHelpers/    # Helper 함수
│       └── NetworkKitExample/
│           ├── Sources/                      # Example 앱 소스
│           │   ├── App/                      # 앱 진입점
│           │   │   ├── NetworkKitExampleApp.swift # @main
│           │   │   └── RootView.swift        # 3-Column Layout
│           │   ├── Features/                 # 기능별 화면
│           │   │   ├── EndpointsList/        # API 엔드포인트 목록
│           │   │   ├── APISpec/              # API 명세 뷰
│           │   │   └── APITester/            # API 테스터 뷰
│           │   ├── ViewModels/               # AsyncViewModel
│           │   │   └── APITesterViewModel.swift
│           │   ├── Repositories/             # Repository 계층
│           │   │   └── APITestRepository.swift
│           │   ├── Models/                   # 도메인 모델
│           │   │   ├── APIEndpoint.swift
│           │   │   ├── APIParameter.swift
│           │   │   ├── APIResponse.swift
│           │   │   └── RequestBody.swift
│           │   ├── Data/                     # 정적 데이터
│           │   │   └── APIEndpointsData.swift # JSONPlaceholder API 정의
│           │   └── Logger/                   # 로깅 통합
│           │       ├── TraceKitNetworkLogger.swift
│           │       └── TraceKitViewModelLogger.swift
│           ├── Resources/                    # Assets
│           └── Tests/                        # Example 테스트
```

이 구조는 [AsyncViewModel](https://github.com/Jimmy-Jung/AsyncViewModel) 프로젝트의 베스트 프랙티스를 따릅니다.

## 특징

- ✅ 순수 Foundation (URLSession, Codable, async/await)
- ✅ 외부 의존성 제로
- ✅ Dependency Injection 기반 로깅
- ✅ Chain of Responsibility 패턴 응답 처리
- ✅ 재시도 정책 지원
- ✅ Swift Concurrency 완벽 지원
- ✅ Swift 6.0 Strict Concurrency
- ✅ SPM 패키지 (코어 라이브러리)
- ✅ Tuist 프로젝트 (Example 앱)

## 설치

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/NetworkKit.git", from: "1.0.0")
]
```

## 개발 환경 설정

### 1. NetworkKit 코어 라이브러리 (SPM)

```bash
# 루트 디렉토리에서

# 빌드
swift build

# 테스트
swift test

# Xcode로 열기
open Package.swift
```

### 2. NetworkKitExample 앱 (Tuist)

```bash
# NetworkKitExample 폴더로 이동
cd Projects/NetworkKitExample

# Tuist 의존성 가져오기
tuist install

# 프로젝트 생성
tuist generate

# 빌드
tuist build NetworkKitExample

# Xcode로 열기 (생성 후)
open NetworkKitExample.xcworkspace
```

## 빠른 시작

### 1. API Request 정의

```swift
import NetworkKit

enum MyAPI {
    case getUsers
}

extension MyAPI: APIRequest {
    var baseURL: URL {
        URL(string: "https://api.example.com")!
    }
    
    var path: String {
        "/users"
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var task: HTTPTask {
        .requestPlain
    }
    
    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
    
    var validationType: ValidationType {
        .successCodes
    }
}
```

### 2. Response 모델 정의

```swift
struct User: Codable, Sendable {
    let id: Int
    let name: String
}
```

### 3. NetworkService 사용

```swift
import NetworkKit

// NetworkService 생성
let logger = ConsoleNetworkLogger(options: NetworkLoggingOptions(
    logLevel: .verbose,
    logRequest: true,
    logResponse: true,
    logError: true
))

let networkService = NetworkKit.createNetworkService(
    logger: logger,
    configuration: .development
)

// API 요청
do {
    let users = try await networkService.request(
        request: MyAPI.getUsers,
        decodeType: [User].self
    )
    print("Users: \(users)")
} catch {
    print("Error: \(error)")
}
```

## 핵심 컴포넌트

### NetworkKit Factory

간편한 NetworkService 생성

```swift
// 기본 설정
let service = NetworkKit.createNetworkService()

// 커스텀 로거
let service = NetworkKit.createNetworkService(
    logger: ConsoleNetworkLogger(),
    configuration: .production
)

// Raw Response용
let rawService = NetworkKit.createRawNetworkService()
```

### HTTPClient

URLSession 기반 HTTP 클라이언트

```swift
let client = HTTPClient(logger: ConsoleNetworkLogger())
```

### NetworkLogger

DI 기반 로깅 프로토콜

```swift
public protocol NetworkLogger: Sendable {
    var options: NetworkLoggingOptions { get set }
    func logRequest(_ request: URLRequest, target: (any APIRequest)?)
    func logResponse(_ response: HTTPResponse, target: (any APIRequest)?)
    func logError(_ error: Error, target: (any APIRequest)?)
}

// 기본 제공: ConsoleNetworkLogger, SilentNetworkLogger
```

### ResponseProcessor

Chain of Responsibility 패턴 응답 처리

```swift
struct MyCustomStep: ResponseProcessorStep {
    func process(
        _ response: HTTPResponse,
        request: (any APIRequest)?
    ) -> Result<HTTPResponse, NetworkError> {
        // 커스텀 처리 로직
        return .success(response)
    }
}

let processor = ResponseProcessor(
    steps: [
        StatusCodeValidationStep(),
        MyCustomStep()
    ]
)
```

### RetryPolicy

재시도 정책

```swift
let retryPolicy = RetryPolicy(
    maxRetries: 3,
    retryableErrors: [.timeout, .networkConnectionLost],
    retryableStatusCodes: [408, 429, 500, 502, 503, 504],
    baseDelay: 1.0,
    maxDelay: 60.0
)
```

## Example 앱 실행

NetworkKitExample은 JSONPlaceholder API를 테스트할 수 있는 인터랙티브 Playground입니다.

### 주요 기능
- 📱 **3-Column NavigationSplitView**: API 목록 → 명세 → 테스트
- 🔍 **실시간 검색**: API 엔드포인트 빠른 검색
- 🧪 **인터랙티브 테스트**: Parameters, Request Body 입력 후 실제 요청
- 📊 **상세 응답 표시**: Status Code, Headers, Body (Pretty JSON)
- 💾 **State 캐싱**: 엔드포인트별 마지막 응답 자동 저장
- 📝 **TraceKit 로깅**: OSLog 통합 구조화 로그

### Tuist 명령어

```bash
cd Projects/NetworkKitExample

# 의존성 가져오기
tuist install

# 프로젝트 생성
tuist generate

# 빌드
tuist build NetworkKitExample

# 테스트
tuist test NetworkKitExample

# Xcode로 열기
open NetworkKitExample.xcworkspace

# 정리
tuist clean
```

자세한 내용은 [NetworkKitExample README](./Projects/NetworkKitExample/README.md)를 참고하세요.

## 요구사항

### NetworkKit 코어 라이브러리
- iOS 13.0+
- macOS 10.15+
- tvOS 13.0+
- watchOS 6.0+
- Swift 6.0+
- Xcode 16.0+

### NetworkKitExample 앱
- iOS 17.0+ (NavigationSplitView 사용)
- Swift 6.0+
- Xcode 16.0+
- Tuist (프로젝트 생성 필요)

## 참고 프로젝트

이 프로젝트는 [AsyncViewModel](https://github.com/Jimmy-Jung/AsyncViewModel)의 프로젝트 구조를 참고했습니다.

### 프로젝트 구조 철학
- **SPM 패키지** (루트): 코어 라이브러리 배포용
- **Projects/NetworkKit/**: 실제 라이브러리 소스 및 테스트
- **Projects/NetworkKitExample/**: Tuist 기반 Example 앱
  - AsyncViewModel + TraceKit 통합 데모
  - JSONPlaceholder API Playground
  - 3-Column NavigationSplitView
- **ProjectDescriptionHelpers**: Tuist 설정 재사용

## 라이선스

MIT License

---

**NetworkKit** - 순수 Foundation 기반의 Swift 네트워크 라이브러리

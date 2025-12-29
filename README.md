<div align="center">

# NetworkKit

### 순수 Foundation 기반의 Swift 네트워크 라이브러리

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2013%2B%20%7C%20macOS%2010.15%2B%20%7C%20tvOS%2013%2B%20%7C%20watchOS%206%2B-lightgrey.svg)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Jimmy-Jung/NetworkKit)](https://github.com/Jimmy-Jung/NetworkKit/releases)
[![CI](https://github.com/Jimmy-Jung/NetworkKit/actions/workflows/ci.yml/badge.svg)](https://github.com/Jimmy-Jung/NetworkKit/actions/workflows/ci.yml)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)

[English](#) | [한국어](#-korean)

</div>

---

## 왜 NetworkKit인가?

NetworkKit은 순수 Foundation만을 사용하여 구축된 현대적인 Swift 네트워크 라이브러리입니다.

### 주요 특징

- ✅ **순수 Foundation**: URLSession, Codable, async/await만 사용 (외부 의존성 제로)
- ⚡ **Swift Concurrency 네이티브**: async/await 완벽 지원
- 🧱 **계층화된 아키텍처**: Core → Infrastructure → Application → Orchestration
- 🔄 **재시도 정책**: 유연한 재시도 전략 (지수 백오프, 커스텀 규칙)
- 🔗 **Chain of Responsibility 패턴**: 확장 가능한 응답 처리 파이프라인
- 📝 **Dependency Injection 로깅**: 프로토콜 기반 로거 교체 가능
- 🧪 **테스트 용이성**: MockURLProtocol 기반 단위 테스트 지원
- 🎯 **타입 안전성**: Sendable 완벽 준수 (Swift 6.0 Strict Concurrency)
- 📦 **SPM 패키지**: Swift Package Manager로 간편 설치

### 다른 라이브러리와 비교

| 특징 | NetworkKit | Alamofire | Moya |
|------|-----------|-----------|------|
| 외부 의존성 | ✅ 없음 | ❌ AFNetworking | ❌ Alamofire |
| Swift Concurrency | ✅ 네이티브 | ✅ 지원 | ⚠️ 부분 지원 |
| 계층화 아키텍처 | ✅ 4계층 | ⚠️ 단일 계층 | ✅ 계층화 |
| 재시도 정책 | ✅ 내장 | ✅ 내장 | ⚠️ 플러그인 |
| 코드 크기 | 🟢 작음 | 🟡 중간 | 🟡 중간 |
| 학습 곡선 | ⭐⭐ 보통 | ⭐ 쉬움 | ⭐⭐ 보통 |

### 누가 사용하면 좋을까요?

- ✅ 외부 의존성 없이 순수 Foundation만 사용하고 싶은 팀
- ✅ Swift Concurrency를 활용한 현대적인 네트워크 코드를 원하는 개발자
- ✅ 계층화된 아키텍처로 확장 가능한 네트워크 레이어를 구축하려는 프로젝트
- ✅ 재시도 정책과 에러 처리를 세밀하게 제어하고 싶은 경우
- ✅ 테스트 가능한 네트워크 코드를 작성하려는 팀

## 목차

- [왜 NetworkKit인가?](#왜-networkkit인가)
- [빠른 시작](#빠른-시작)
- [설치](#설치)
- [핵심 개념](#핵심-개념)
- [아키텍처](#아키텍처)
- [기본 사용법](#기본-사용법)
- [고급 기능](#고급-기능)
- [Example 앱](#example-앱)
- [테스트](#테스트)
- [문서](#문서)
- [기여하기](#기여하기)
- [라이선스](#라이선스)

## 빠른 시작

### 1. API Request 정의

```swift
import NetworkKit

enum MyAPI {
    case getUsers
    case getUser(id: Int)
    case createUser(name: String)
}

extension MyAPI: APIRequest {
    var baseURL: URL {
        URL(string: "https://api.example.com")!
    }
    
    var path: String {
        switch self {
        case .getUsers:
            return "/users"
        case .getUser(let id):
            return "/users/\(id)"
        case .createUser:
            return "/users"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getUsers, .getUser:
            return .get
        case .createUser:
            return .post
        }
    }
    
    var task: HTTPTask {
        switch self {
        case .getUsers, .getUser:
            return .requestPlain
        case .createUser(let name):
            return .requestParameters(
                parameters: ["name": name],
                encoding: .json
            )
        }
    }
    
    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
}
```

### 2. Response 모델 정의

```swift
struct User: Codable, Sendable {
    let id: Int
    let name: String
    let email: String
}
```

### 3. NetworkService 사용

```swift
import NetworkKit

// NetworkService 생성 (Factory 사용)
let networkService = NetworkKit.createNetworkService(
    interceptors: [ConsoleLoggingInterceptor()],
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

## 설치

### 요구사항

| 플랫폼 | 최소 버전 |
|--------|----------|
| iOS | 13.0+ |
| macOS | 10.15+ |
| tvOS | 13.0+ |
| watchOS | 6.0+ |
| Swift | 6.0+ |
| Xcode | 16.0+ |

### Swift Package Manager

#### Package.swift에 추가

```swift
dependencies: [
    .package(url: "https://github.com/Jimmy-Jung/NetworkKit.git", from: "1.0.0")
]
```

**타겟 의존성 추가:**

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "NetworkKit", package: "NetworkKit")
    ]
)
```

#### Xcode에서 추가

1. **File → Add Package Dependencies...**
2. 검색창에 입력: `https://github.com/Jimmy-Jung/NetworkKit.git`
3. **Add Package** 클릭
4. **`NetworkKit`** 선택

## 핵심 개념

NetworkKit은 **계층화된 아키텍처**로 설계되었습니다:

```
┌──────────────────────────────────────┐
│      Orchestration Layer             │  NetworkService, ResponseProcessor
│      (비즈니스 로직 조율)              │
└──────────────┬───────────────────────┘
               │
┌──────────────▼───────────────────────┐
│      Application Layer                │  RetryPolicy, ErrorMapper
│      (애플리케이션 정책)               │
└──────────────┬───────────────────────┘
               │
┌──────────────▼───────────────────────┐
│      Infrastructure Layer             │  HTTPClient, ResponseDecoder
│      (인프라 구현)                     │
└──────────────┬───────────────────────┘
               │
┌──────────────▼───────────────────────┐
│      Core Layer                       │  APIRequest, HTTPMethod, HTTPTask
│      (핵심 타입 정의)                  │
└──────────────────────────────────────┘
```

### 주요 컴포넌트

| 컴포넌트 | 역할 | 위치 |
|---------|------|------|
| **APIRequest** | API 엔드포인트 정의 프로토콜 | Core |
| **HTTPClient** | URLSession 기반 HTTP 클라이언트 | Infrastructure |
| **NetworkService** | 네트워크 요청 오케스트레이터 | Orchestration |
| **RetryPolicy** | 재시도 정책 | Application |
| **ResponseProcessor** | Chain of Responsibility 응답 처리 | Orchestration |
| **NetworkLogger** | DI 기반 로깅 프로토콜 | Core |

## 아키텍처

### 계층별 책임

#### 1️⃣ Core Layer (핵심 타입)

순수 타입 정의만 포함합니다:

- `APIRequest`: API 엔드포인트 프로토콜
- `HTTPMethod`: HTTP 메서드 (GET, POST, PUT, DELETE 등)
- `HTTPTask`: 요청 타입 (Plain, Parameters, Upload, Download)
- `HTTPResponse`: HTTP 응답 래퍼
- `NetworkLogger`: 로거 프로토콜

#### 2️⃣ Infrastructure Layer (인프라 구현)

Foundation 기반 구현체:

- `HTTPClient`: URLSession 래퍼
- `ResponseDecoder`: Codable 디코딩
- `StatusCodeValidator`: HTTP 상태 코드 검증

#### 3️⃣ Application Layer (애플리케이션 정책)

비즈니스 정책:

- `RetryPolicy`: 재시도 전략 (지수 백오프, 재시도 가능 에러/상태 코드)
- `ErrorMapper`: 에러 변환

#### 4️⃣ Orchestration Layer (조율)

컴포넌트 통합:

- `NetworkService`: 요청 실행, 재시도, 응답 처리
- `ResponseProcessor`: Chain of Responsibility 패턴 응답 파이프라인

### 데이터 흐름

```mermaid
sequenceDiagram
    participant Client
    participant NetworkService
    participant RetryPolicy
    participant HTTPClient
    participant ResponseProcessor
    participant API
    
    Client->>NetworkService: request(_:decodeType:)
    NetworkService->>RetryPolicy: shouldRetry?
    RetryPolicy->>NetworkService: yes/no
    NetworkService->>HTTPClient: request(_:)
    HTTPClient->>API: URLSession
    API-->>HTTPClient: HTTPResponse
    HTTPClient-->>NetworkService: HTTPResponse
    NetworkService->>ResponseProcessor: process(response)
    ResponseProcessor->>ResponseProcessor: StatusCodeValidation
    ResponseProcessor->>ResponseProcessor: CustomSteps
    ResponseProcessor-->>NetworkService: Validated Response
    NetworkService->>Client: Decoded Data
```

## 기본 사용법

### NetworkService Factory

간편하게 NetworkService를 생성합니다:

```swift
import NetworkKit

// 기본 설정 (Console Logging)
let service = NetworkKit.createNetworkService()

// 커스텀 Interceptors + 환경 설정
let service = NetworkKit.createNetworkService(
    interceptors: [
        ConsoleLoggingInterceptor(minimumLevel: .verbose),
        AuthInterceptor()
    ],
    configuration: .development
)

// 로깅 없이 (빈 Interceptors)
let service = NetworkKit.createNetworkService(
    interceptors: [],
    configuration: .production
)
```

### APIRequest 프로토콜

```swift
public protocol APIRequest: Sendable {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var task: HTTPTask { get }
    var headers: [String: String]? { get }
    var validationType: ValidationType { get }
}
```

### HTTPTask 타입

```swift
public enum HTTPTask: Sendable {
    case requestPlain                                           // 파라미터 없음
    case requestParameters(parameters: [String: Any],           // URL 파라미터
                          encoding: ParameterEncoding)
    case requestJSONEncodable(encodable: any Encodable)         // JSON Body
    case requestData(data: Data)                                // Raw Data
    case uploadMultipart(formData: [MultipartFormData])         // Multipart
    case downloadDestination(destination: URL)                  // 파일 다운로드
}
```

### 재시도 정책

```swift
let retryPolicy = RetryPolicy(
    maxRetries: 3,
    retryableErrors: [.timeout, .networkConnectionLost],
    retryableStatusCodes: [408, 429, 500, 502, 503, 504],
    baseDelay: 1.0,         // 초기 대기 시간
    maxDelay: 60.0,         // 최대 대기 시간
    multiplier: 2.0         // 지수 백오프 배율
)

let service = NetworkService(
    httpClient: HTTPClient(),
    retryPolicy: retryPolicy,
    configuration: .production
)
```

### 커스텀 Logging Interceptor

```swift
struct AnalyticsInterceptor: RequestInterceptor {
    func willSend(_ request: URLRequest, target: (any APIRequest)?) async {
        // 요청 시작 Analytics
        Analytics.track("API Request", properties: [
            "url": request.url?.absoluteString ?? "",
            "method": request.httpMethod ?? ""
        ])
    }
    
    func didReceive(_ response: HTTPResponse, target: (any APIRequest)?) async {
        // 응답 Analytics
        Analytics.track("API Response", properties: [
            "url": response.url.absoluteString,
            "statusCode": response.statusCode
        ])
    }
}

// 사용
let service = NetworkService(
    httpClient: HTTPClient(),
    retryPolicy: .default,
    configuration: .production,
    responseProcessor: ResponseProcessor(),
    interceptors: [AnalyticsInterceptor()]
)
```

## 고급 기능

### ResponseProcessor (Chain of Responsibility)

응답 처리 파이프라인을 커스터마이징할 수 있습니다:

```swift
struct MyAuthenticationStep: ResponseProcessorStep {
    func process(
        _ response: HTTPResponse,
        request: (any APIRequest)?
    ) -> Result<HTTPResponse, NetworkError> {
        // 401 Unauthorized 처리
        if response.statusCode == 401 {
            return .failure(.unauthorized)
        }
        return .success(response)
    }
}

struct MyRateLimitStep: ResponseProcessorStep {
    func process(
        _ response: HTTPResponse,
        request: (any APIRequest)?
    ) -> Result<HTTPResponse, NetworkError> {
        // 429 Too Many Requests 처리
        if response.statusCode == 429 {
            let retryAfter = response.headers["Retry-After"]
            return .failure(.rateLimitExceeded(retryAfter: retryAfter))
        }
        return .success(response)
    }
}

let processor = ResponseProcessor(
    steps: [
        StatusCodeValidationStep(),   // 기본 상태 코드 검증
        MyAuthenticationStep(),        // 커스텀: 인증
        MyRateLimitStep()              // 커스텀: Rate Limiting
    ]
)

let service = NetworkService(
    httpClient: HTTPClient(),
    retryPolicy: .default,
    configuration: .production,
    responseProcessor: processor
)
```

### RequestInterceptor

요청 전/후 처리:

```swift
struct AuthInterceptor: RequestInterceptor {
    func prepare(_ request: inout URLRequest, target: (any APIRequest)?) async throws {
        // 토큰 추가
        let token = try await TokenManager.shared.getToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    func willSend(_ request: URLRequest, target: (any APIRequest)?) async {
        print("🚀 Sending: \(request.url?.absoluteString ?? "")")
    }
    
    func didReceive(_ response: HTTPResponse, target: (any APIRequest)?) async {
        print("✅ Received: \(response.statusCode)")
    }
}
```

### Multipart Form Data

파일 업로드:

```swift
enum UploadAPI: APIRequest {
    case uploadImage(image: UIImage, userId: String)
    
    var task: HTTPTask {
        switch self {
        case .uploadImage(let image, let userId):
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                return .requestPlain
            }
            
            return .uploadMultipart(formData: [
                MultipartFormData(
                    data: imageData,
                    name: "image",
                    fileName: "profile.jpg",
                    mimeType: "image/jpeg"
                ),
                MultipartFormData(
                    data: userId.data(using: .utf8)!,
                    name: "userId"
                )
            ])
        }
    }
}
```

## Example 앱

NetworkKitExample은 JSONPlaceholder API를 테스트할 수 있는 **인터랙티브 API Playground**입니다.

### 주요 기능

- 📱 **3-Column NavigationSplitView**: API 목록 → 명세 → 테스트
- 🔍 **실시간 검색**: API 엔드포인트 빠른 검색
- 🧪 **인터랙티브 테스트**: Parameters, Request Body 입력 후 실제 요청
- 📊 **상세 응답 표시**: Status Code, Headers, Body (Pretty JSON)
- 💾 **State 캐싱**: 엔드포인트별 마지막 응답 자동 저장
- 📝 **TraceKit 로깅**: OSLog 통합 구조화 로그

### 기술 스택

- **NetworkKit**: 네트워크 레이어
- **AsyncViewModel**: 상태 관리 (단방향 데이터 흐름)
- **TraceKit**: 구조화된 로깅
- **Tuist**: 프로젝트 관리

### 실행 방법

```bash
cd Projects/NetworkKitExample

# 의존성 가져오기
tuist install

# 프로젝트 생성
tuist generate

# Xcode로 열기
open NetworkKitExample.xcworkspace
```

자세한 내용은 [NetworkKitExample README](./Projects/NetworkKitExample/README.md)를 참고하세요.

## 테스트

NetworkKit은 테스트하기 쉽게 설계되었습니다.

### MockURLProtocol 사용

```swift
import Testing
@testable import NetworkKit

@Test("사용자 목록 조회 성공")
func testGetUsersSuccess() async throws {
    // Given
    let mockJSON = """
    [
        {"id": 1, "name": "John"},
        {"id": 2, "name": "Jane"}
    ]
    """
    
    MockURLProtocol.requestHandler = { request in
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, mockJSON.data(using: .utf8)!)
    }
    
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: config)
    
    let client = HTTPClient(session: session)
    let service = NetworkService(httpClient: client)
    
    // When
    let users = try await service.request(
        request: MyAPI.getUsers,
        decodeType: [User].self
    )
    
    // Then
    #expect(users.count == 2)
    #expect(users[0].name == "John")
}

@Test("재시도 정책 테스트")
func testRetryPolicy() async throws {
    var attemptCount = 0
    
    MockURLProtocol.requestHandler = { request in
        attemptCount += 1
        
        if attemptCount < 3 {
            throw NetworkError.timeout
        }
        
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (response, Data())
    }
    
    let retryPolicy = RetryPolicy(
        maxRetries: 3,
        retryableErrors: [.timeout],
        baseDelay: 0.1
    )
    
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    let client = HTTPClient(session: URLSession(configuration: config))
    let service = NetworkService(
        httpClient: client,
        retryPolicy: retryPolicy
    )
    
    // When
    _ = try await service.requestRaw(request: MyAPI.getUsers)
    
    // Then
    #expect(attemptCount == 3)
}
```

## 문서

### 📚 프로젝트 구조

```
NetworkKit/
├── Package.swift                    # SPM 패키지 정의
├── Projects/
│   ├── NetworkKit/                  # Core 라이브러리
│   │   ├── Sources/
│   │   │   ├── Core/                # 핵심 타입
│   │   │   ├── Infrastructure/      # 인프라 구현
│   │   │   ├── Application/         # 애플리케이션 정책
│   │   │   └── Orchestration/       # 오케스트레이션
│   │   └── Tests/                   # 단위 테스트
│   └── NetworkKitExample/           # Example 앱 (Tuist)
└── .github/                         # GitHub 설정 (CI/CD)
```

### 🎯 추가 리소스

- 📱 [Example 앱 README](Projects/NetworkKitExample/README.md) - 인터랙티브 API Playground
- 🐛 [Issues](https://github.com/Jimmy-Jung/NetworkKit/issues) - 버그 리포트 및 기능 제안
- 💬 [Discussions](https://github.com/Jimmy-Jung/NetworkKit/discussions) - 질문 및 피드백

## 기여하기

NetworkKit은 오픈소스 프로젝트이며, 여러분의 기여를 환영합니다! 🎉

### 기여 방법

1. **이슈 확인**: [Issues](https://github.com/Jimmy-Jung/NetworkKit/issues)에서 해결하고 싶은 문제 찾기
2. **Fork**: 저장소를 Fork합니다
3. **브랜치 생성**: `git checkout -b feature/amazing-feature`
4. **변경사항 작성**: 코드 작성 및 테스트 추가
5. **커밋**: `git commit -m 'feat: add amazing feature'`
6. **푸시**: `git push origin feature/amazing-feature`
7. **Pull Request**: GitHub에서 PR 생성

### 기여 가이드

자세한 기여 방법은 [CONTRIBUTING.md](.github/CONTRIBUTING.md)를 참고해주세요:
- 코딩 규칙
- 커밋 컨벤션
- PR 프로세스
- 테스트 작성 가이드

### 좋은 첫 이슈

처음 기여하시나요? [`good first issue`](https://github.com/Jimmy-Jung/NetworkKit/labels/good%20first%20issue) 라벨이 붙은 이슈부터 시작해보세요!

## 라이선스

NetworkKit은 [MIT License](LICENSE)로 배포됩니다.

```
MIT License

Copyright (c) 2025 Jimmy Jung

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 감사의 말

NetworkKit은 다음 프로젝트들에서 영감을 받았습니다:

- [Alamofire](https://github.com/Alamofire/Alamofire) - Swift HTTP 네트워킹 라이브러리
- [Moya](https://github.com/Moya/Moya) - 계층화된 네트워크 추상화
- [AsyncViewModel](https://github.com/Jimmy-Jung/AsyncViewModel) - 프로젝트 구조 참고

그리고 프로젝트에 기여해주신 모든 분들께 감사드립니다! 🙏

## 만든 사람

**Jimmy Jung (정준영)**  
iOS Developer from Seoul, South Korea 🇰🇷

- GitHub: [@Jimmy-Jung](https://github.com/Jimmy-Jung)
- Email: joony300@gmail.com

## 후원

NetworkKit이 도움이 되었나요? ⭐ Star를 눌러주세요!

프로젝트 개발을 지원하고 싶으시다면:
- ⭐ GitHub Star
- 🐛 버그 리포트 및 기능 제안
- 📝 문서 개선
- 💻 코드 기여
- 📢 프로젝트 공유

---

<div align="center">

**Made with ❤️ and ☕ in Seoul, Korea**

[⬆ 맨 위로](#networkkit)

</div>

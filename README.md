# AsyncNetwork

Foundation, Network, Swift Concurrency 기반으로 구성한 Swift 네트워크 라이브러리입니다.  
명시적인 `APIRequest` 선언, property wrapper 기반 파라미터 구성, `NetworkService` preset, 재시도 정책, 인터셉터, 네트워크 상태 확인을 한 번에 제공합니다.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2013%2B%20%7C%20macOS%2010.15%2B%20%7C%20tvOS%2013%2B%20%7C%20watchOS%206%2B-lightgrey.svg)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Jimmy-Jung/AsyncNetwork)](https://github.com/Jimmy-Jung/AsyncNetwork/releases)

## 핵심 기능

- `APIRequest` 기반의 명시적인 요청 정의
- `@QueryParameter`, `@PathParameter`, `@RequestBody`, `@HeaderField`, `@CustomHeader`
- `NetworkService`의 `request`, `requestData`, `requestRaw`
- `RetryPolicy`와 `RetryConfiguration` 기반 재시도 제어
- `RequestInterceptor` 기반 요청/응답 가로채기
- `ResponseProcessor`, `StatusCodeValidator`, `ResponseDecoder`
- `NetworkMonitor.shared` 기반 네트워크 연결 상태 확인
- `AsyncNetwork` 우산 모듈 + `AsyncNetworkCore` 코어 product 제공

## 3.0 변경점

- 매크로 기반 선언(`@APIRequest`, `@ResponseTestable`) 제거
- 일반 Swift 타입과 프로토콜 중심 구조로 정리
- `AsyncNetwork`는 유지하되 내부 구현은 `AsyncNetworkCore`를 재노출하는 얇은 우산 모듈로 단순화

기존 매크로 기반 요청은 일반 `APIRequest` 타입으로 옮겨야 합니다.

## 설치

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Jimmy-Jung/AsyncNetwork.git", from: "3.0.0")
]
```

일반적인 앱/모듈에서는 `AsyncNetwork`만 추가하면 됩니다.

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "AsyncNetwork", package: "AsyncNetwork")
    ]
)
```

코어 모듈을 직접 선택하고 싶다면 `AsyncNetworkCore`도 사용할 수 있습니다.

```swift
.target(
    name: "YourCoreTarget",
    dependencies: [
        .product(name: "AsyncNetworkCore", package: "AsyncNetwork")
    ]
)
```

## 빠른 시작

```swift
import AsyncNetwork

struct Post: Codable, Sendable {
    let id: Int
    let title: String
}

struct GetPostsRequest: APIRequest {
    typealias Response = [Post]

    let baseURLString = "https://jsonplaceholder.typicode.com"
    let path = "/posts"
    let method: HTTPMethod = .get

    @QueryParameter var userId: Int?
    @QueryParameter(key: "_limit") var limit: Int?

    init(userId: Int? = nil, limit: Int? = nil) {
        self.userId = userId
        self.limit = limit
    }
}

let service = NetworkService.default(interceptors: [])
let posts = try await service.request(GetPostsRequest(limit: 10))
```

## 주요 구성

### `APIRequest`

요청 정의에 필요한 최소 정보만 요구합니다.

```swift
public protocol APIRequest: Sendable {
    associatedtype Response: Decodable = EmptyResponse

    var baseURLString: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var timeout: TimeInterval { get }
}
```

`APIRequest.asURLRequest()`를 통해 최종 `URLRequest`로 변환할 수 있습니다.

### Property Wrappers

- `@QueryParameter`: 쿼리 스트링 추가
- `@PathParameter`: 경로 플레이스홀더 치환
- `@RequestBody`: JSON body 인코딩
- `@HeaderField`: 표준 헤더 키 기반 헤더 추가
- `@CustomHeader`: 커스텀 헤더 추가

```swift
struct UpdatePostRequest: APIRequest {
    typealias Response = Post

    let baseURLString = "https://jsonplaceholder.typicode.com"
    let path = "/posts/{id}"
    let method: HTTPMethod = .put

    @PathParameter var id: Int
    @RequestBody var body: UpdatePostBody
    @HeaderField(key: .contentType) var contentType: String = "application/json"
    @CustomHeader("X-Trace-Id") var traceId: String?
}
```

### `NetworkService`

```swift
let service = NetworkService(
    httpClient: HTTPClient(),
    retryPolicy: RetryPolicy(configuration: .patient),
    interceptors: [ConsoleLoggingInterceptor(minimumLevel: .info)],
    networkMonitor: NetworkMonitor.shared
)
```

주요 메서드:

- `request(_:)`: `APIRequest.Response`로 디코딩
- `request(request:decodeType:)`: 원하는 `Decodable` 타입으로 디코딩
- `requestData(_:)`: 원시 `Data` 반환
- `requestRaw(_:)`: `HTTPResponse` 반환

제공 preset:

- `NetworkService.default()`: 일반 JSON API
- `NetworkService.image()`: 이미지 다운로드
- `NetworkService.upload()`: 파일 업로드
- `NetworkService.download()`: 대용량 다운로드
- `NetworkService.realtime()`: 빠른 실패가 중요한 실시간 요청
- `NetworkService.offline()`: 캐시 우선 오프라인 친화 요청

### `HTTPClientConfiguration`

`HTTPClient`는 timeout, cache policy, connectivity, 동시 연결 수를 직접 조정할 수 있습니다.

```swift
let client = HTTPClient(
    configuration: HTTPClientConfiguration(
        timeoutForRequest: 15,
        timeoutForResource: 60,
        cachePolicy: .reloadIgnoringLocalCacheData,
        waitsForConnectivity: true
    )
)
```

미리 준비된 설정:

- `HTTPClientConfiguration.image`
- `HTTPClientConfiguration.upload`
- `HTTPClientConfiguration.download`
- `HTTPClientConfiguration.realtime`
- `HTTPClientConfiguration.offline`

### 재시도, 인터셉터, 네트워크 모니터링

```swift
let retryPolicy = RetryPolicy(configuration: .quick)
let logger = ConsoleLoggingInterceptor(minimumLevel: .debug)
let service = NetworkService(
    retryPolicy: retryPolicy,
    interceptors: [logger],
    networkMonitor: NetworkMonitor.shared
)
```

- `RetryConfiguration.standard`, `.quick`, `.patient`
- `URLErrorRetryRule`, `ServerErrorRetryRule`
- `ConsoleLoggingInterceptor`
- `NetworkMonitor.shared`

## Example App

예제 앱은 실제 화면에서 `AsyncNetwork` 사용 흐름을 확인하기 위한 참고 프로젝트입니다.

- 경로: [Examples/AsyncNetworkExampleApp](Examples/AsyncNetworkExampleApp)
- 화면: `Basics`, `Recipes`, `Monitor`
- 데모 내용: property wrapper, service preset, interceptor, retry, offline guard

바로 열기:

```bash
open Examples/AsyncNetworkExampleApp/AsyncNetworkExampleApp.xcworkspace
```

프로젝트를 다시 생성해야 하면:

```bash
cd Examples/AsyncNetworkExampleApp
tuist install
tuist generate --no-open
```

## 로컬 개발

라이브러리 자체를 열어서 작업하려면 루트 workspace를 사용하면 됩니다.

```bash
open AsyncNetwork.xcworkspace
```

기본 요구 환경:

- Xcode 16.0+
- Swift 6.0+
- macOS 14.0+

## 테스트

```bash
swift build
swift test
```

현재 테스트는 다음 범위를 포함합니다.

- `APIRequest.asURLRequest()` 변환
- `NetworkService` 요청, 재시도, 오프라인 처리
- property wrapper 동작
- `HTTPClient`, `RetryPolicy`, `ResponseProcessor`
- `NetworkMonitor`
- `import AsyncNetwork` 공개 표면 smoke test

## 매크로 버전에서 마이그레이션

기존:

```swift
@APIRequest(
    response: User.self,
    baseURL: "https://api.example.com",
    path: "/users/{id}",
    method: .get
)
struct GetUserRequest {
    @PathParameter var id: Int
}
```

이후:

```swift
struct GetUserRequest: APIRequest {
    typealias Response = User

    let baseURLString = "https://api.example.com"
    let path = "/users/{id}"
    let method: HTTPMethod = .get

    @PathParameter var id: Int
}
```

## 프로젝트 구조

```text
AsyncNetwork/
├── Package.swift
├── AsyncNetwork.xcodeproj
├── AsyncNetwork.xcworkspace
├── Examples/
│   └── AsyncNetworkExampleApp/
├── Projects/
│   └── AsyncNetwork/
│       ├── Sources/
│       └── Tests/
├── Tuist/
└── .github/
```

## License

MIT

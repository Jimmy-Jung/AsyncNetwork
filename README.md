# AsyncNetwork

Foundation과 Swift Concurrency만으로 구성한 Swift 네트워크 라이브러리입니다.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2013%2B%20%7C%20macOS%2010.15%2B%20%7C%20tvOS%2013%2B%20%7C%20watchOS%206%2B-lightgrey.svg)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Jimmy-Jung/AsyncNetwork)](https://github.com/Jimmy-Jung/AsyncNetwork/releases)

## What Stays

- `APIRequest` 기반의 명시적인 요청 정의
- `NetworkService` 기반의 async/await 요청 실행
- `@QueryParameter`, `@PathParameter`, `@RequestBody`, `@HeaderField` property wrapper
- 재시도 정책, 인터셉터, 응답 처리 파이프라인
- `NetworkMonitor` 기반 네트워크 상태 확인

## What Changed In 3.0

- 매크로(`@APIRequest`, `@ResponseTestable`) 제거
- 매크로 전용 샘플 앱, OpenAPI 예제, 생성 스크립트 제거
- 공개 product `AsyncNetwork`는 유지, 내부 구현은 코어-only로 단순화

기존 매크로 사용 코드는 일반 `APIRequest` 타입으로 옮겨야 합니다.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Jimmy-Jung/AsyncNetwork.git", from: "3.0.0")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "AsyncNetwork", package: "AsyncNetwork")
    ]
)
```

## Quick Start

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

let service = NetworkService()
let posts = try await service.request(GetPostsRequest(limit: 10))
```

## Example App

실제 화면에서 `AsyncNetwork` 사용 흐름을 따라가려면 Example App을 열면 됩니다.

- 경로: [Examples/AsyncNetworkExampleApp](/Users/jimmy/Documents/GitHub/AsyncNetwork/Examples/AsyncNetworkExampleApp)
- 구성: `Basics`, `Recipes`, `Monitor`
- 목적: 요청 정의, 서비스 구성, 오프라인 처리까지 한 번에 참고

```bash
open Examples/AsyncNetworkExampleApp/AsyncNetworkExampleApp.xcworkspace
```

## Core API

### `APIRequest`

`APIRequest`는 요청 실행에 필요한 최소 정보만 요구합니다.

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

### Property Wrappers

- `@QueryParameter`: 쿼리 문자열
- `@PathParameter`: 경로 치환
- `@RequestBody`: JSON body
- `@HeaderField`: 표준 헤더 키

```swift
struct UpdatePostRequest: APIRequest {
    typealias Response = Post

    let baseURLString = "https://jsonplaceholder.typicode.com"
    let path = "/posts/{id}"
    let method: HTTPMethod = .put

    @PathParameter var id: Int
    @RequestBody var body: UpdatePostBody?
    @HeaderField(key: .contentType) var contentType: String? = "application/json"
}
```

### `NetworkService`

```swift
let service = NetworkService(
    httpClient: HTTPClient(),
    retryPolicy: RetryPolicy(configuration: .patient),
    interceptors: [ConsoleLoggingInterceptor(minimumLevel: .info)]
)
```

미리 준비된 프리셋도 제공합니다.

- `NetworkService.default()`
- `NetworkService.image()`
- `NetworkService.upload()`
- `NetworkService.download()`
- `NetworkService.realtime()`
- `NetworkService.offline()`

## Testing

```bash
swift build
swift test
```

패키지 테스트는 다음을 검증합니다.

- `APIRequest.asURLRequest()` 변환
- `NetworkService` 요청, 재시도, 오프라인 처리
- property wrapper 동작
- `import AsyncNetwork` 공개 표면 smoke test

## Migration From Macro-Based Versions

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

## Project Structure

```text
AsyncNetwork/
├── Package.swift
├── Examples/
│   └── AsyncNetworkExampleApp/
├── Projects/
│   └── AsyncNetwork/
│       ├── Sources/
│       └── Tests/
└── .github/
```

## License

MIT

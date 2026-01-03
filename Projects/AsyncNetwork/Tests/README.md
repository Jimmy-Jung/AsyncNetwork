# AsyncNetwork Tests

AsyncNetwork 라이브러리의 테스트 스위트입니다. 테스트는 Sources 폴더 구조와 동일하게 구성되어 있습니다.

## 📁 테스트 폴더 구조

```
Tests/
├── Client/                    # HTTP 클라이언트 테스트
│   ├── HTTPClientTests.swift
│   └── HTTPClientAdvancedTests.swift
├── Configuration/             # 네트워크 설정 테스트
│   └── NetworkConfigurationTests.swift
├── Errors/                    # 에러 처리 테스트
│   └── ErrorMapperTests.swift
├── Helpers/                   # 테스트 헬퍼 및 유틸리티
│   ├── MockURLProtocol.swift
│   ├── AsyncNetworkFactoryTests.swift
│   ├── NetworkLogPluginTests.swift
│   └── PerformanceBaselineTests.swift
├── Interceptors/              # 인터셉터 테스트
│   └── LoggingInterceptorTests.swift
├── Models/                    # 모델 테스트
│   ├── HTTPHeadersTests.swift
│   └── HTTPModelsTests.swift
├── Processing/                # 응답 처리 테스트
│   ├── ResponseDecoderTests.swift
│   ├── ResponseProcessorTests.swift
│   ├── ServerResponseValidatorTests.swift
│   └── StatusCodeValidatorTests.swift
├── Protocols/                 # 프로토콜 테스트
│   └── APIRequestTests.swift
├── Service/                   # 네트워크 서비스 테스트
│   ├── NetworkServiceTests.swift
│   ├── NetworkServiceAdvancedTests.swift
│   ├── NetworkServiceOfflineTests.swift
│   ├── RetryPolicyTests.swift
│   └── RetryRuleTests.swift
└── Utilities/                 # 유틸리티 테스트
    ├── AsyncDelayerTests.swift
    └── NetworkMonitorTests.swift
```

## 🧪 테스트 카테고리

### Client (2개 파일, 19개 테스트)

HTTP 클라이언트의 기본 및 고급 기능 테스트:

- **HTTPClientTests**: 기본 HTTP 요청, 404 에러, 네트워크 에러 처리
- **HTTPClientAdvancedTests**: 엣지 케이스, 다양한 HTTP 메서드, 헤더, 상태 코드, 동시성, 요청 바디

### Configuration (1개 파일)

네트워크 설정 관련 테스트:

- **NetworkConfigurationTests**: 타임아웃, 캐시 정책, 설정 값 검증

### Errors (1개 파일)

에러 매핑 및 처리 테스트:

- **ErrorMapperTests**: NetworkError 매핑, 재시도 가능 여부 판단, 에러 로깅

### Helpers (4개 파일)

테스트 지원 유틸리티 및 팩토리 테스트:

- **MockURLProtocol**: URLProtocol Mock 구현 (Swift Concurrency 안전)
- **AsyncNetworkFactoryTests**: 팩토리 패턴 생성 테스트
- **NetworkLogPluginTests**: 로깅 플러그인 테스트
- **PerformanceBaselineTests**: 성능 기준선 테스트

### Interceptors (1개 파일)

요청/응답 인터셉터 테스트:

- **LoggingInterceptorTests**: 로깅 인터셉터, 민감 정보 마스킹, 로그 레벨

### Models (2개 파일)

HTTP 모델 및 헤더 테스트:

- **HTTPHeadersTests**: HTTP 헤더 빌더, 타입 안전한 헤더 관리
- **HTTPModelsTests**: HTTPMethod, HTTPResponse 등 기본 모델

### Processing (4개 파일)

응답 처리 파이프라인 테스트:

- **ResponseDecoderTests**: JSON 디코딩, 빈 응답, 디코딩 실패
- **ResponseProcessorTests**: Chain of Responsibility 패턴, 프로세서 체인
- **ServerResponseValidatorTests**: 서버 응답 검증
- **StatusCodeValidatorTests**: HTTP 상태 코드 검증 (2xx, 3xx, 4xx, 5xx)

### Protocols (1개 파일)

프로토콜 구현 테스트:

- **APIRequestTests**: APIRequest 프로토콜, URLRequest 변환, Property Wrapper 적용

### Service (5개 파일, 22개 테스트)

네트워크 서비스 핵심 기능 테스트:

- **NetworkServiceTests**: 기본 요청/디코딩, associatedtype Response, EmptyResponse
- **NetworkServiceAdvancedTests**: 디코딩 엣지 케이스, 재시도 로직, 인터셉터 체인
- **NetworkServiceOfflineTests**: 오프라인 감지, 네트워크 상태 확인
- **RetryPolicyTests**: 재시도 정책, 지수 백오프, 최대 재시도 횟수
- **RetryRuleTests**: 재시도 규칙, URLError, StatusCodeValidationError

### Utilities (2개 파일)

유틸리티 기능 테스트:

- **AsyncDelayerTests**: 비동기 지연, 테스트 가능한 지연 유틸리티
- **NetworkMonitorTests**: 네트워크 연결 상태 감지, 연결 타입 확인

## 🎯 테스트 실행

### 전체 테스트 실행

```bash
swift test
```

### 특정 카테고리 테스트 실행

```bash
# Client 테스트만 실행
swift test --filter HTTPClientTests

# Service 테스트만 실행
swift test --filter NetworkServiceTests

# Advanced 테스트만 실행
swift test --filter "HTTPClientAdvancedTests|NetworkServiceAdvancedTests"
```

### 특정 테스트 실행

```bash
# 특정 테스트 메서드만 실행
swift test --filter HTTPClientTests.successfulGetRequest
```

## 📊 테스트 통계

- **총 테스트 수**: 477개
- **테스트 파일 수**: 22개
- **테스트 카테고리**: 9개
- **테스트 커버리지**: 핵심 기능 전체

## 🛠 테스트 작성 가이드

### 1. 테스트 파일 위치

Sources 폴더 구조와 동일한 경로에 테스트 파일을 배치합니다.

```
Sources/Client/HTTPClient.swift
  ↓
Tests/Client/HTTPClientTests.swift
```

### 2. 테스트 파일 네이밍

- 기본 테스트: `{ClassName}Tests.swift`
- 고급/엣지 케이스: `{ClassName}AdvancedTests.swift`
- 특정 시나리오: `{ClassName}{Scenario}Tests.swift`

예:
- `HTTPClientTests.swift` - 기본 기능
- `HTTPClientAdvancedTests.swift` - 고급 기능 및 엣지 케이스
- `NetworkServiceOfflineTests.swift` - 오프라인 시나리오

### 3. Swift Testing 프레임워크 사용

```swift
import Testing
@testable import AsyncNetworkCore

struct HTTPClientTests {
    @Test("테스트 설명")
    func testMethodName() async throws {
        // Given
        let expected = "value"
        
        // When
        let actual = try await someMethod()
        
        // Then
        #expect(actual == expected)
    }
    
    @Test("매개변수화 테스트", arguments: [200, 201, 204])
    func testMultipleValues(statusCode: Int) async throws {
        // 여러 값에 대해 반복 테스트
    }
}
```

### 4. MockURLProtocol 사용

```swift
// Given
let path = "/test"
let configuration = URLSessionConfiguration.ephemeral
configuration.protocolClasses = [MockURLProtocol.self]
let session = URLSession(configuration: configuration)

await MockURLProtocol.register(path: path) { request in
    let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )!
    return (response, Data("success".utf8))
}

// When
let response = try await client.request(TestAPIRequest(path: path))

// Then
#expect(response.statusCode == 200)
```

### 5. 테스트 구조

#### Given-When-Then 패턴

```swift
@Test("설명")
func testMethod() async throws {
    // Given - 테스트 준비
    let client = HTTPClient(session: session)
    
    // When - 실제 동작
    let result = try await client.request(request)
    
    // Then - 결과 검증
    #expect(result.statusCode == 200)
}
```

#### Actor 사용 (상태 관리)

```swift
actor RequestState {
    private(set) var attemptCount = 0
    
    func incrementAndGet() -> Int {
        attemptCount += 1
        return attemptCount
    }
}
```

## 🔍 테스트 범위

### 커버된 시나리오

✅ 성공 케이스
- 다양한 HTTP 메서드 (GET, POST, PUT, PATCH, DELETE)
- 다양한 상태 코드 (2xx, 3xx, 4xx, 5xx)
- JSON 디코딩
- 빈 응답 처리

✅ 에러 케이스
- 네트워크 에러 (URLError)
- HTTP 에러 (상태 코드)
- 디코딩 에러
- 오프라인 감지

✅ 엣지 케이스
- 빈 응답 데이터
- 큰 응답 데이터 (1MB)
- 특수 문자 경로
- 중첩 경로
- 동시 요청 (10개)
- 재시도 로직
- 인터셉터 체인

✅ 성능
- 동시성 처리
- 재시도 지연
- 응답 속도

## 📝 테스트 작성 체크리스트

새로운 기능을 추가할 때 다음 테스트를 작성하세요:

- [ ] 정상 동작 테스트 (Happy Path)
- [ ] 에러 케이스 테스트
- [ ] 엣지 케이스 테스트
- [ ] 매개변수화 테스트 (여러 값)
- [ ] 비동기 동작 테스트
- [ ] 동시성 안전성 테스트 (필요 시)

## 🚀 CI/CD 통합

GitHub Actions, GitLab CI 등에서 테스트 실행:

```yaml
- name: Run Tests
  run: swift test --enable-code-coverage
```

## 📚 참고 자료

- [Swift Testing 프레임워크](https://developer.apple.com/documentation/testing)
- [AsyncNetwork 기여 가이드](../../CONTRIBUTING.md)
- [AsyncNetwork README](../../README.md)


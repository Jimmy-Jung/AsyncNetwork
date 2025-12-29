# Changelog

All notable changes to AsyncNetwork will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-29

### Added

#### Core Features
- 순수 Foundation 기반 네트워크 라이브러리 구현
- Swift Concurrency (async/await) 완벽 지원
- Swift 6.0 Strict Concurrency 준수

#### Network Client
- `HTTPClient`: URLSession 기반 네트워크 클라이언트
- `HTTPHeaders`: 타입 안전한 HTTP 헤더 관리
- `NetworkService`: 고수준 네트워크 서비스 추상화

#### Request & Response
- `APIRequest`: 프로토콜 기반 API 정의
- `HTTPMethod`: GET, POST, PUT, DELETE, PATCH 지원
- `HTTPTask`: 요청 바디 및 파라미터 처리
- `HTTPResponse`: 타입 안전한 응답 모델
- `ServerResponse`: 서버 응답 래퍼

#### Response Processing
- Chain of Responsibility 패턴 기반 응답 처리 파이프라인
- `StatusCodeValidator`: HTTP 상태 코드 검증
- `ResponseDecoder`: JSON 디코딩
- `ResponseProcessor`: 커스터마이블 응답 처리

#### Retry & Error Handling
- `RetryPolicy`: 유연한 재시도 정책
- `RetryRule`: 프로토콜 기반 재시도 규칙
- `ErrorMapper`: 에러 매핑 및 변환
- 지수 백오프 (Exponential Backoff) 지원

#### Interceptors
- `RequestInterceptor`: 요청/응답 인터셉터 프로토콜
- `LoggingInterceptor`: 네트워크 로깅 인터셉터

#### Configuration
- `NetworkConfiguration`: 네트워크 설정 관리
- 타임아웃, 헤더, 재시도 정책 설정 지원

#### Testing Support
- `MockURLProtocol`: 단위 테스트를 위한 Mock 프로토콜
- 100% 테스트 커버리지 달성
- Swift Testing 프레임워크 기반 테스트

#### Platform Support
- iOS 13.0+
- macOS 10.15+
- tvOS 13.0+
- watchOS 6.0+

#### Developer Experience
- Swift Package Manager 지원
- 포괄적인 문서 및 예제
- Example 앱 제공 (API Tester)
- CI/CD 파이프라인 (GitHub Actions)
- 코드 커버리지 리포팅

### Documentation
- 상세한 README 작성
- API 사용 가이드
- 아키텍처 문서
- 코드 예제 및 베스트 프랙티스

[1.0.0]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/v1.0.0


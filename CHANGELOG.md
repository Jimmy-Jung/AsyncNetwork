# Changelog

All notable changes to AsyncNetwork will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-01-02

### 🎉 Initial Release

AsyncNetwork 1.0.0 정식 출시! 순수 Foundation 기반의 현대적인 Swift 네트워크 라이브러리입니다.

### ✨ Added

#### Core Features
- **APIRequest Protocol**: 프로토콜 기반 API 요청 정의
- **NetworkService**: 네트워크 요청을 처리하는 핵심 서비스
- **HTTPClient**: URLSession 기반 HTTP 클라이언트
- **HTTPResponse**: 응답 데이터를 캡슐화하는 모델

#### Property Wrappers
- `@QueryParameter`: URL 쿼리 파라미터 선언적 정의
- `@PathParameter`: URL 경로 파라미터 선언적 정의
- `@RequestBody`: JSON 요청 바디 선언적 정의
- `@HeaderField`: HTTP 헤더 선언적 정의

#### Macro Support
- `@APIRequest`: API 요청 구조체 자동 생성 매크로
  - 보일러플레이트 코드 제거
  - 타입 안전한 API 정의
  - 코드 생성 시점 검증

#### Configuration & Policy
- **NetworkConfiguration**: 네트워크 설정 (타임아웃, 캐시 정책 등)
- **RetryPolicy**: 재시도 정책 (지수 백오프, 커스텀 규칙)
- **RetryRule Protocol**: 커스텀 재시도 규칙 정의

#### Interceptors
- **RequestInterceptor Protocol**: 요청/응답 인터셉터 인터페이스
- **LoggingInterceptor**: 네트워크 로깅 인터셉터

#### Response Processing
- **ResponseProcessor**: Chain of Responsibility 패턴 기반 응답 처리
- **ResponseProcessorStep Protocol**: 커스텀 프로세서 단계 정의
- **StatusCodeValidator**: HTTP 상태 코드 검증
- **ResponseDecoder**: JSON 디코딩

#### Error Handling
- **NetworkError**: 네트워크 에러 타입 정의
- **ErrorMapper**: 에러 매핑 및 변환

#### Utilities
- **AsyncDelayer**: 테스트 가능한 비동기 지연 유틸리티

#### Testing Support
- **MockURLProtocol**: 테스트용 Mock 프로토콜
- 의존성 주입 설계로 테스트 용이성 향상

### 📦 Packages

- **AsyncNetworkCore**: 핵심 네트워크 기능
- **AsyncNetworkMacros**: 매크로 구현
- **AsyncNetwork**: Umbrella 프레임워크 (Core + Macros 통합)

### 🎯 Platform Support

- iOS 13.0+
- macOS 10.15+
- tvOS 13.0+
- watchOS 6.0+

### 🔧 Technical Details

- Swift 6.0
- Swift Concurrency (async/await, Actor)
- Swift Package Manager
- Zero external dependencies (순수 Foundation)

### 📝 Documentation

- 상세한 README.md 작성
- 코드 문서화 (DocC 지원)
- 사용 예제 및 튜토리얼

### 🧪 Tests

- 단위 테스트 커버리지 확보
- Swift Testing 프레임워크 사용
- MockURLProtocol 기반 테스트

---

## [1.1.0] - 2026-01-03

### ✨ Added

#### Documentation Kit
- **AsyncNetworkDocKit**: API 문서 자동 생성 프레임워크 추가
  - `@APIRequest` 매크로 메타데이터를 활용한 인터랙티브 문서 앱 생성
  - 3열 레이아웃 (API 리스트 / 상세 설명 / 실시간 테스터)
  - 실시간 API 테스트 기능
  - 카테고리별 API 분류
  - 검색 기능
  - 다크모드 지원

#### Utilities
- **NetworkMonitor**: 실시간 네트워크 연결 상태 감지
  - Wi-Fi, 셀룰러, 이더넷 연결 타입 감지
  - SwiftUI 및 Combine 지원
  - NetworkService와 통합된 오프라인 체크

### 🔧 Changed

- NetworkService에 네트워크 연결 상태 확인 기능 추가
- 오프라인 상태에서 즉시 에러 반환 기능 추가

### 📦 Packages

- **AsyncNetworkDocKit**: iOS 전용 문서 생성 프레임워크 추가

### 🎯 Platform Support

- AsyncNetworkDocKit: iOS 17.0+ (SwiftUI 필수)

---

## [Unreleased]

### Planned Features

- [ ] WebSocket 지원
- [ ] Multipart/Form-Data 업로드
- [ ] 다운로드 진행률 추적
- [ ] HTTP/2 Server Push 지원
- [ ] 네트워크 모니터링 (NWPathMonitor 통합)

---

[1.1.0]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.1.0
[1.0.0]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.0.0


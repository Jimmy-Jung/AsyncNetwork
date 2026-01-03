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
  - 실시간 API 테스트 기능 (`APITesterView`)
  - 카테고리별 API 분류 (`EndpointCategory`)
  - 동적 API 요청 실행 (`DynamicAPIRequest`)
  - 타입 구조 시각화 (`TypeStructure`, `TypeStructureView`)
  - 검색 기능
  - 다크모드 지원

#### Property Wrappers
- `@CustomHeader`: 커스텀 HTTP 헤더 선언적 정의
  - 동적 헤더 키 지원
  - 타입 안전한 커스텀 헤더 추가

#### Utilities
- **NetworkMonitor**: 실시간 네트워크 연결 상태 감지
  - Wi-Fi, 셀룰러, 이더넷 연결 타입 감지
  - SwiftUI 및 Combine 지원
  - NetworkService와 통합된 오프라인 체크

#### Scripts
- **CreateDocKitExample.swift**: 샘플 앱 자동 생성 스크립트
  - 대화형 입력 모드
  - 경로 자동 정규화 (절대/상대/홈 경로)
  - Tuist 모듈 자동 감지
  - Placeholder 파일 자동 생성
  - 빌드 스크립트 자동 설정
- **GenerateTypeRegistration.swift**: `@DocumentedType` 등록 코드 생성
  - 타입 자동 스캔 및 등록
  - 타임스탬프 및 통계 정보 자동 기록
- **GenerateEndpoints.swift**: `@APIRequest` 엔드포인트 생성
  - tags 기반 카테고리 자동 분류
  - 엔드포인트 딕셔너리 자동 생성

### 🔧 Changed

- NetworkService에 네트워크 연결 상태 확인 기능 추가
- 오프라인 상태에서 즉시 에러 반환 기능 추가

### 📦 Packages

- **AsyncNetworkDocKit**: iOS 전용 문서 생성 프레임워크 추가

### 🎯 Platform Support

- AsyncNetworkDocKit: iOS 17.0+ (SwiftUI 필수)

### 🧪 Tests

- AsyncNetworkDocKit 테스트 추가
  - `DynamicAPIRequestTests`: 동적 API 요청 테스트
  - `DocKitFactoryTests`: 팩토리 생성 테스트
  - `EndpointCategoryTests`: 카테고리 분류 테스트
  - `RequestBodyParserTests`: 요청 바디 파싱 테스트
  - `APITesterStateTests`: API 테스터 상태 관리 테스트

### 📝 Documentation

- Scripts/README.md 추가 (자동 코드 생성 스크립트 가이드)
- AsyncNetworkDocKitExample 예제 프로젝트 추가

---

## [1.0.2] - 2026-01-03

### 🐛 Fixed

#### Test Performance
- **로깅 테스트 최적화**
  - 모든 LoggingInterceptor 테스트의 로그 레벨을 `.error`로 통일 (19개)
  - NetworkLogPluginTests 로그 레벨 조정 (10개)
  - LoggingInterceptorTests 로그 레벨 조정 (9개)
  - CI 환경에서 stdout 과부하 방지

### 🔧 Changed

- `LoggingInterceptorTests.swift`: 9개 테스트 로그 레벨 통일
- `NetworkLogPluginTests.swift`: 10개 테스트 로그 레벨 통일

### 📊 Impact

- CI 실행 시간 개선 (로그 출력 최소화)
- GitHub Actions 안정성 향상
- 테스트 로직은 동일하게 유지

---

## [1.0.1] - 2026-01-03

### 🐛 Fixed

#### CI Stability
- **NetworkMonitor 테스트 안정성 개선**
  - `.serialized` 옵션으로 순차 실행 강제
  - NWPathMonitor 병렬 실행 시 충돌 방지
  
- **CI 타임아웃 최적화**
  - 대량 로깅 테스트의 로그 레벨 조정 (`.debug` → `.error`)
  - GitHub Actions 워크플로우 타임아웃 5분으로 설정
  - 병렬 테스트 실행 활성화 (`swift test --parallel`)

#### Test Improvements
- **MockURLProtocol 안정성 개선**
  - 불필요한 `clear()` 호출 제거
  - 각 테스트는 고유한 path 사용으로 격리 보장
  - URLError Code=-1000 에러 해결

- **SystemDelayer 테스트 안정성 개선**
  - CI 환경을 고려한 타이밍 검증 완화
  - 최소 경과 시간 체크 제거, 최대값만 확인

### 🔧 Changed

- `.github/workflows/ci.yml`: 타임아웃 및 병렬 실행 설정
- `.github/workflows/release.yml`: 타임아웃 최적화
- `NetworkMonitorTests.swift`: serial 실행 설정 추가
- `NetworkLogPluginTests.swift`: 성능 테스트 로그 레벨 조정
- `AsyncDelayerTests.swift`: CI 친화적 타이밍 검증

### 🧪 Tests

- 전체 364개 테스트 안정성 확보
- CI에서 일관된 테스트 통과 보장

### 🔗 Related Issues

- https://github.com/Jimmy-Jung/AsyncNetwork/actions/runs/20680686006/job/59374462950
- https://github.com/Jimmy-Jung/AsyncNetwork/actions/runs/20679661934/job/59372110459

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
[1.0.2]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.0.2
[1.0.1]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.0.1
[1.0.0]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.0.0


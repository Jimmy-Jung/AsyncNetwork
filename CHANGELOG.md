# Changelog

All notable changes to AsyncNetwork will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### 🔧 Improvements

#### @ResponseTestable Macro - Compile-time JSON Validation
- **Added compile-time validation for fixtureJSON structure**
  - Detects missing required fields and emits warnings
  - Detects extra fields not in struct definition
  - Detects basic type mismatches (Number, String, Boolean, Array, Object)
  - Optional fields are allowed to be missing in fixtureJSON
  - Warnings are emitted at compile-time, allowing early detection of JSON structure errors
  
- **Benefits**
  - Prevents runtime crashes due to invalid fixtureJSON
  - Early detection of JSON structure issues during development
  - Better developer experience with clear warning messages
  
- **Example Warning Messages**
  ```
  ⚠️ fixtureJSON is missing required fields: name, email
  ⚠️ fixtureJSON contains extra fields not in struct: unknownField
  ⚠️ Field 'id' type mismatch: expected Number but got String
  ```

- **Limitations**
  - Only validates top-level fields (nested DTO structures are not deeply validated)
  - Type hints are basic (cannot distinguish Int vs Double, both are "Number")
  - Nested DTOs must each have correct fixtureJSON definitions

### 🧪 Tests

#### @ResponseTestable Macro - Validation Tests
- **Added 5 new test cases for JSON validation**
  - `missingRequiredFields()`: Validates warning for missing required fields
  - `extraFields()`: Validates warning for extra fields
  - `typeMismatch()`: Validates warning for type mismatches
  - `validJSON()`: Validates no warnings for correct JSON
  - `optionalFieldsAllowed()`: Validates optional fields can be omitted

### 📚 Documentation

#### @ResponseTestable Macro - JSON Validation Guide
- **Added comprehensive documentation: `docs/ResponseTestable-JSON-Validation.md`**
  - Problem description with real-world example
  - Validation features explanation
  - Code change details
  - Validation limitations and workarounds
  - Best practices and migration guide

---

## [1.2.4] - 2026-01-29

### 🔒 Security

#### @APIDocument Macro - Special Character Escape Fix
- **Fixed critical string escape vulnerabilities in @APIDocument macro**
  - Added `escapeForStringLiteral()` helper function to properly escape special characters
  - Fixed unescaped special characters in `tags` array elements (HIGH priority)
  - Fixed unescaped special characters in `headerKey` for @HeaderField and @CustomHeader (HIGH priority)
  - Fixed unescaped special characters in `baseURL` when using string literals (MEDIUM priority)
  - Fixed unescaped special characters in `path` (MEDIUM priority)
  - Fixed unescaped special characters in `typeName`, `responseType`, and parameter names (LOW priority)
  - Special characters now properly escaped: `\`, `"`, `\n`, `\r`, `\t`

### 🧪 Tests

#### @APIDocument Macro - Enhanced Test Coverage
- **Added 7 new test cases for special character handling**
  - Test for tags with quotes: `["Test\"Tag"]`
  - Test for tags with backslashes: `["Category\\Path"]`
  - Test for title and description with special chars: `"Get \"all\" posts"`, `"Line1\nLine2"`
  - Test for baseURL with special chars: `"https://api.test.com/\"endpoint\""`
  - Test for path with special chars: `"/posts/{id}/comments\"test"`
  - Test for tabs and carriage returns: `"Get\tposts"`, `"Line1\r\nLine2\tTabbed"`
  - Test for multiple special chars combined
- **Added integration test in MacroCompositionTests**
  - Test for special characters in all fields with PropertyWrappers

### 📊 Test Results

- All 242 tests passed successfully
- No linter errors detected
- All special character edge cases now properly handled

### 📦 Sample Code

#### Course Example Implementation
- **Added CourseDTO and CourseRequests example code**
  - CourseDTO: Codable DTO for course data with test support
  - CourseRequests: Complete API request examples using all macros
  - GetCoursesRequest: GET request with query parameters and documentation
  - GetCourseDetailRequest: GET request with path parameters
  - CreateCourseRequest: POST request with request body
  - UpdateCourseRequest: PUT request with both path and body parameters
  - DeleteCourseRequest: DELETE request with path parameter
  - Test files: CourseDTOTests and CourseRequestsTests

---

## [Unreleased]

### Planned Features

- [ ] WebSocket 지원
- [ ] Multipart/Form-Data 업로드
- [ ] 다운로드 진행률 추적
- [ ] HTTP/2 Server Push 지원

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

## [1.0.5] - 2026-01-04

### 🐛 Fixed

#### CI Stability
- **병렬 실행 제거 및 타임아웃 조정**
  - `--parallel` 옵션 제거 (순차 실행으로 변경)
  - 타임아웃 5분 → 15분으로 조정
  - 병렬 실행의 오버헤드 및 리소스 경합 제거

### 🔧 Changed

- `.github/workflows/ci.yml`: 순차 실행 및 타임아웃 15분 설정

### 📊 Impact

- CI 안정성 극대화 (타임아웃 문제 완전 해결)
- 총 364개 테스트의 순차 실행 보장
- 매크로 테스트 컴파일 시간 충분히 확보

### 📝 Background

- 364개 테스트 × 2.6초 = 약 15.7분 소요 예상
- 병렬 실행이 오히려 macOS CI 환경에서 오버헤드 발생
- 순차 실행이 더 안정적이고 예측 가능

---

## [1.0.4] - 2026-01-03

### 🔧 Changed

#### CI Configuration
- **CI 타임아웃 최적화**
  - Build and Test 타임아웃을 10분에서 5분으로 조정
  - 5분 이상 걸리는 테스트는 문제가 있는 것으로 판단
  - 빠른 피드백 제공

### 📊 Impact

- CI 워크플로우 실행 시간 최적화
- 타임아웃으로 인한 빠른 실패 감지
- 불필요한 대기 시간 감소

---

## [1.0.3] - 2026-01-03

### 🐛 Fixed

#### Test Stability
- **NetworkMonitor 관련 멈춤 완전 해결**
  - DocKitFactoryTests: NetworkMonitor 비활성화
  - AsyncNetworkFactoryTests: 4개 테스트에서 NetworkMonitor 비활성화
  - CI 환경에서 NWPathMonitor로 인한 멈춤 완전 차단

### 🔧 Changed

- `DocKitFactoryTests.swift`: createTestNetworkService()에서 networkMonitor: nil 설정
- `AsyncNetworkFactoryTests.swift`: 모든 NetworkService 생성 테스트 수정
  - createNetworkServiceWithDefaults
  - createNetworkServiceWithCustomConfiguration
  - createNetworkServiceWithVariousConfigurations
  - createNetworkServiceWithFullCustomization

### 📊 Impact

- CI 테스트 안정성 극대화
- NetworkMonitor 관련 모든 잠재적 멈춤 제거
- 테스트 로직은 동일하게 유지

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

---

## [1.2.2] - 2026-01-14

### 🔧 Changed

#### CI/CD Automation
- **Auto Tag 워크플로우 개선**
  - release/* 브랜치 머지 시 자동으로 GitHub Release 생성
  - 이전 태그와의 변경사항 자동 수집 및 릴리즈 노트 생성
  - SPM 설치 가이드 자동 포함
  - 수동 릴리즈 생성 프로세스 제거

### 🎯 Impact

- 배포 프로세스 완전 자동화
- 릴리즈 생성 시간 단축 (수동 → 자동)
- 일관된 릴리즈 포맷 보장
- 개발자 경험 개선

---

## [1.2.1] - 2026-01-14

### ✨ Added

#### Network Monitoring
- **ConnectionType 모델 추가**
  - 네트워크 연결 타입을 표현하는 독립적인 모델
  - Wi-Fi, Cellular, Ethernet, Other 타입 정의
  - NetworkMonitor에서 분리하여 재사용성 향상
  - Sendable, Equatable 프로토콜 준수

- **NetworkMonitoringService 추가**
  - UI 레이어에서 네트워크 상태를 관찰할 수 있는 서비스
  - ObservableObject 기반으로 SwiftUI에서 관찰 가능
  - NetworkMonitor의 상태를 UI로 브릿지하는 어댑터 역할
  - AppDependency에 싱글톤으로 등록
  - MockNetworkMonitoringService 테스트 더블 추가

#### Sample App Features
- **API Playground 네트워크 상태 표시**
  - 실시간 네트워크 상태 배너 추가
  - APIMethodListView에서 baseURL 표시 개선
  - APIRequestDetailView에 네트워크 상태 정보 추가
  - APIRequestTesterView에 연결 상태 배지 및 알림
  - 네트워크 미연결 시 사용자 안내 메시지

### 🔧 Changed

#### NetworkMonitor Improvements
- **NetworkMonitoring 프로토콜 개선**
  - onStatusChange 콜백 메서드 추가
  - ConnectionType을 독립 모델로 분리
  - Combine 의존성 제거하여 순수 Foundation 사용
  - 프로토콜 사용 예시 및 설계 철학 문서화
  - summary 기본 구현 추가
  - NetworkService에서 NetworkMonitor 사용 방식 개선

### 🧪 Tests

- **NetworkMonitor 통합 테스트 추가**
  - 네트워크 연결 상태 감지 테스트
  - 상태 변경 콜백 동작 검증
  - NetworkService와의 통합 시나리오 테스트
  - 비용/제한 연결 감지 테스트

### 🐛 Fixed

#### CI/CD
- **PR 단계에서만 테스트 실행**
  - merge 후 중복 테스트 실행 방지
  - CI 워크플로우 효율성 개선

- **Dependabot 설정 수정**
  - Tuist 프로젝트에서 Dependabot 제거
  - Package.swift가 없는 프로젝트 제외

### 📝 Documentation

- NetworkMonitoring 프로토콜 문서화 개선
- NetworkMonitoringService 사용 가이드 추가
- API Playground 기능 설명 추가

### 🎯 Impact

- 네트워크 상태 모니터링 기능 강화
- UI 레이어에서 네트워크 상태 관찰 용이성 향상
- Sample App 사용자 경험 개선
- CI/CD 효율성 향상

---

## [1.2.0] - 2026-01-13

### ✨ Added

#### Macro Architecture Redesign
- **Clean Architecture 기반 매크로 시스템 재설계**
  - Domain Layer: 비즈니스 로직 (Models, Parsers, Validators, Generators)
  - Facade Layer: 단일 진입점 (APIRequestMacroFacade)
  - Infrastructure Layer: SwiftSyntax 기반 기술 (DiagnosticBuilder, ExpressionParser, SyntaxExtensions)

#### Domain Layer Components
- **Models**
  - `MacroArguments`: 매크로 인자 표현
  - `MacroContext`: 매크로 실행 컨텍스트
  - `MacroError`: 매크로 에러 정의
  - `PropertyInfo`: 프로퍼티 메타데이터
  - `PropertyWrapperSuggestion`: Property Wrapper 제안

- **Parsers**
  - `APIRequestArgumentParser`: 매크로 인자 파싱
  - `PathParser`: URL 경로 파싱 및 검증

- **Validators**
  - `MacroValidator`: 매크로 전체 검증
  - `PropertyWrapperValidator`: Property Wrapper 검증 및 제안

- **Generators**
  - `CodeGenerator`: Swift 코드 생성
  - `MetadataGenerator`: OpenAPI 메타데이터 생성
  - `PathGenerator`: HTTP 경로 생성
  - `PropertyGenerator`: 프로퍼티 코드 생성
  - `TestGenerator`: 테스트 코드 생성

#### Infrastructure Components
- `DiagnosticBuilder`: SwiftSyntax 진단 메시지 생성
- `ExpressionParser`: Swift 표현식 파싱
- `SyntaxExtensions`: SwiftSyntax 확장 유틸리티

### 🧪 Tests

#### Domain Tests (7개 파일, 454+ 테스트)
- `APIRequestArgumentParserTests`: 매크로 인자 파싱 검증
- `ExpressionParserTests`: 표현식 파싱 테스트
- `MetadataGeneratorTests`: 메타데이터 생성 검증
- `PathGeneratorTests`: 경로 생성 로직 테스트
- `PathParserTests`: 경로 파싱 및 검증
- `PropertyGeneratorTests`: 프로퍼티 생성 테스트
- `PropertyWrapperValidatorTests`: Property Wrapper 검증

#### Integration Tests (3개 파일)
- `E2ETests`: 엔드투엔드 시나리오 테스트
- `APIRequestMacroIntegrationTests`: 매크로 통합 동작 검증
- `ErrorHandlingIntegrationTests`: 에러 처리 시나리오

#### NetworkService Tests
- `NetworkServiceTests`: 비동기 작업 테스트 개선
- `NetworkServiceAdvancedTests`: 재시도, 인터셉터, 복잡한 시나리오
- `TestHelpers`: 테스트 환경 설정 유틸리티

### 🔧 Changed

- 매크로 구현체를 레거시 코드에서 Clean Architecture로 전환
- 코드 스타일 개선 (SwiftFormat, SwiftLint 적용)
- 테스트 커버리지 대폭 강화

### 📝 Documentation

- README.md: 1.2.0 버전 업데이트
- 매크로 아키텍처 섹션 추가
- Clean Architecture 설계 원칙 문서화

### 🎯 Design Principles

- **단일 책임 원칙**: 각 컴포넌트는 하나의 책임만
- **의존성 역전**: 도메인은 인프라에 의존하지 않음
- **테스트 용이성**: 각 레이어 독립 테스트 가능

---

[1.2.4]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.2.4
[1.2.2]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.2.2
[1.2.1]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.2.1
[1.2.0]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.2.0
[1.1.0]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.1.0
[1.0.5]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.0.5
[1.0.4]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.0.4
[1.0.3]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.0.3
[1.0.2]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.0.2
[1.0.1]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.0.1
[1.0.0]: https://github.com/Jimmy-Jung/AsyncNetwork/releases/tag/1.0.0


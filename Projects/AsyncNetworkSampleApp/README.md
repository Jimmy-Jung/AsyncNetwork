# AsyncNetworkSampleApp - 재설계 완료

AsyncNetwork 프레임워크의 모든 기능을 테스트할 수 있는 종합 데모 앱입니다.

## 📋 개요

AsyncNetwork의 주요 기능을 직관적으로 탐색하고 테스트할 수 있도록 5개 탭으로 재구성되었습니다.

## 🗂️ 화면 구성 (5개 탭)

### 1️⃣ API 데모 (`APIDemoViewController`)
**목적**: HTTP 메서드 및 Property Wrappers 테스트

**주요 기능**:
- 📄 모든 게시글 조회 (GET)
- 🔍 쿼리 파라미터 (`@QueryParameter`)
- 🆔 경로 파라미터 (`@PathParameter`)
- ➕ 게시글 생성 (POST, `@RequestBody`)
- ✏️ 게시글 수정 (PUT)
- 🔧 부분 수정 (PATCH)
- ❌ 게시글 삭제 (DELETE)
- 📋 헤더 예제 (`@HeaderField`, `@CustomHeader`)

**구현 상태**: 🟡 Placeholder (준비 중)

---

### 2️⃣ 인터셉터 (`InterceptorViewController`)
**목적**: RequestInterceptor 체인 시각화 및 테스트

**주요 기능**:
- 🔌 인터셉터 활성화/비활성화
  - ☑️ 콘솔 로깅 (`ConsoleLoggingInterceptor`)
  - ☑️ 인증 토큰 주입 (`AuthInterceptor`)
  - ☐ 커스텀 헤더 주입
  - ☐ 타임스탬프 로거
- 📊 인터셉터 체인 순서 표시
- 🧪 테스트 요청 전송
- 📋 인터셉터 로그 실시간 표시

**구현 상태**: 🟡 Placeholder (준비 중)

---

### 3️⃣ 재시도 (`RetrySimulatorViewController`)
**목적**: RetryPolicy 동작 시각화

**주요 기능**:
- 🎛️ 정책 선택
  - ◉ 기본 (3회, 1초 지연)
  - ○ 적극적 (5회, 0.5초)
  - ○ 보수적 (1회, 2초)
  - ○ 커스텀 (직접 설정)
- 🎯 에러 유형 시뮬레이션
  - 타임아웃
  - 서버 에러 (500)
  - 연결 끊김
  - 404 Not Found
  - 401 Unauthorized
- 📊 재시도 타임라인 시각화
- 📈 통계 (총 시도, 성공률, 소요 시간)

**구현 상태**: 🟡 Placeholder (준비 중)

---

### 4️⃣ 모니터 (`NetworkMonitorViewController`)
**목적**: NetworkMonitor 실시간 상태 표시

**주요 기능**:
- 🌐 연결 상태 표시
  - 🟢 연결됨 / 🔴 연결 해제
  - 연결 타입 (Wi-Fi, Cellular, Ethernet)
- 📊 연결 세부 정보
  - 비용 발생 여부 (isExpensive)
  - 제한 여부 (isConstrained)
  - IPv4/IPv6 지원
- 🧪 오프라인 시뮬레이션
- 📡 네트워크 활동 로그
- 📋 이벤트 로그

**구현 상태**: 🟡 Placeholder (준비 중)

---

### 5️⃣ 설정 (`SettingsViewController`)
**목적**: NetworkConfiguration 및 전역 설정 관리

**주요 기능**:
- ⚙️ 네트워크 구성 (5가지)
  - Development, Default, Stable, Fast, Test
- 🔄 재시도 정책 (4가지)
  - Default, Aggressive, Conservative, None
- 📝 로깅 레벨 (4가지)
  - Verbose, Info, Error, None
- 🛠️ 개발자 도구
  - Error Simulator (구현 완료 ✅)
  - OpenAPI 문서 보기
  - API 테스트 플레이그라운드
  - 성능 지표

**구현 상태**: 🟢 완료 (Error Simulator 포함)

---

## 🏗️ 아키텍처

### MVVM + AsyncViewModel

```
View (UIViewController)
    ↓
ViewModel (@AsyncViewModel)
    ↓
UseCase (Business Logic)
    ↓
Repository (Protocol)
    ↓
NetworkService (@APIRequest)
```

### 데이터 흐름 (AsyncViewModel)

```
Input → Action → Reduce → State 업데이트 + Effect
                              ↓
                         @Published
                              ↓
                            View
```

---

## 📁 프로젝트 구조

```
AsyncNetworkSampleApp/
├── App/
│   ├── AsyncNetworkSampleApp.swift      # @main
│   ├── AppDependency.swift               # DI Container
│   ├── MainTabBarController.swift       # 5개 탭 구조 ✅
│   └── SceneDelegate.swift
│
├── Presentation/
│   ├── APIDemo/
│   │   ├── APIDemoViewController.swift  # Placeholder ✅
│   │   └── APIDemoViewModel.swift       # 구현 중 🟡
│   │
│   ├── Interceptor/
│   │   └── InterceptorViewController.swift  # Placeholder ✅
│   │
│   ├── Retry/
│   │   └── RetrySimulatorViewController.swift  # Placeholder ✅
│   │
│   ├── Monitor/
│   │   └── NetworkMonitorViewController.swift  # Placeholder ✅
│   │
│   ├── Settings/
│   │   ├── SettingsViewController.swift       # 완료 ✅
│   │   ├── SettingsViewModel.swift            # 완료 ✅
│   │   ├── ErrorSimulatorViewController.swift # 완료 ✅
│   │   └── ErrorSimulatorViewModel.swift      # 완료 ✅
│   │
│   └── (기존 Posts, Users, Albums - 참고용)
│
├── Domain/
│   ├── Models/
│   │   ├── APIRequestCatalog.swift      # 완료 ✅
│   │   ├── ErrorSimulator.swift         # 완료 ✅
│   │   └── Settings.swift               # 완료 ✅
│   │
│   ├── Repositories/
│   └── UseCases/
│
└── Data/
    ├── API/
    │   └── Requests/
    │       └── PostRequests.swift       # PATCH 추가 ✅
    │
    └── Repositories/
```

---

## 🚀 시작하기

### 필수 요구사항

- Xcode 16.0 이상
- Swift 6.0 이상
- macOS 14.0 이상
- Tuist 4.x

### 설치 및 실행

```bash
# 1. 프로젝트 디렉토리로 이동
cd Projects/AsyncNetworkSampleApp

# 2. Tuist 의존성 설치
tuist install

# 3. 프로젝트 생성
tuist generate

# 4. Xcode에서 열기
open AsyncNetworkSampleApp.xcworkspace
```

### 빌드 및 실행

1. Xcode에서 `AsyncNetworkSampleApp` 스킴 선택
2. 시뮬레이터 또는 실제 기기 선택
3. ⌘R로 빌드 및 실행

---

## 🧪 테스트

### 단위 테스트

```bash
# 전체 테스트 실행
tuist test AsyncNetworkSampleApp

# 특정 테스트만 실행
xcodebuild test -workspace AsyncNetworkSampleApp.xcworkspace \
  -scheme AsyncNetworkSampleApp \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:AsyncNetworkSampleAppTests/ErrorSimulatorTests
```

### TDD로 구현된 모델

- ✅ `APIRequestCatalog` - 메타데이터 기반 API 카탈로그
- ✅ `ErrorSimulator` - 8개 테스트 통과
- ✅ `Settings` - ETag 캐시 설정 지원

---

## 📊 구현 현황

| 탭 | 화면 | ViewModel | 테스트 | 상태 |
|----|-----|-----------|--------|------|
| API 데모 | ✅ | 🟡 | 🟡 | Placeholder |
| 인터셉터 | ✅ | ⬜ | ⬜ | Placeholder |
| 재시도 | ✅ | ⬜ | ⬜ | Placeholder |
| 모니터 | ✅ | ⬜ | ⬜ | Placeholder |
| 설정 | ✅ | ✅ | ✅ | 완료 |

**전체 진행률**: 40% (5개 중 2개 완료)

---

## 🔥 AsyncNetwork 기능 매핑

| AsyncNetwork 기능 | 시연 탭 | 구현 상태 |
|------------------|--------|----------|
| @APIRequest 매크로 | API 데모 | 🟡 |
| Property Wrappers | API 데모 | 🟡 |
| RequestInterceptor | 인터셉터 | ⬜ |
| ConsoleLoggingInterceptor | 인터셉터 | ⬜ |
| RetryPolicy | 재시도 | ⬜ |
| RetryConfiguration | 재시도 | ⬜ |
| NetworkMonitor | 모니터 | ⬜ |
| NetworkConfiguration | 설정 | ✅ |
| Error Simulator | 설정 | ✅ |

---

## 📚 참고 자료

- [AsyncNetwork README](../../README.md)
- [아키텍처 설계](./ARCHITECTURE.md)
- [Error Simulator 구현](./ERROR_SIMULATOR_IMPLEMENTATION.md)
- [Settings 구현](./SETTINGS_IMPLEMENTATION.md)
- [AsyncNetwork 사용 가이드](../../.cursor/rules/spec/asynchnetwork/RULE.mdc)
- [AsyncViewModel 가이드](../../.cursor/rules/spec/asyncviewmodel/RULE.mdc)

---

## 🎯 다음 단계

### Phase 2: API 데모 탭 완성
- [ ] APIDemoViewModel 완성 및 테스트
- [ ] APIDemoViewController UI 구현
- [ ] 각 HTTP 메서드별 상세 화면

### Phase 3: 인터셉터 탭 구현
- [ ] InterceptorConfig 모델
- [ ] InterceptorViewModel
- [ ] 인터셉터 체인 UI

### Phase 4: 재시도 탭 구현
- [ ] RetrySimulation 모델
- [ ] RetrySimulatorViewModel
- [ ] 타임라인 UI

### Phase 5: 모니터 탭 구현
- [ ] NetworkMonitorState 모델
- [ ] NetworkMonitorViewModel
- [ ] 실시간 상태 UI

---

## 📄 라이선스

이 샘플 앱은 AsyncNetwork와 동일한 MIT License를 따릅니다.

---

**Updated**: 2026-01-11  
**Status**: Phase 1 완료 - 5개 탭 구조 재설계 완료 ✅
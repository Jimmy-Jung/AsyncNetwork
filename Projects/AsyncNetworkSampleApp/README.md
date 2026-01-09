# AsyncNetworkSampleApp

AsyncNetwork 프레임워크의 주요 기능을 실제로 보여주는 iOS 샘플 앱입니다.

## 📋 개요

이 앱은 JSONPlaceholder API를 사용하여 Posts, Users, Comments, Albums 등의 데이터를 조회하고 관리하는 기능을 제공합니다. AsyncNetwork의 모든 주요 기능을 실제로 사용하는 예제를 포함합니다.

## 🎯 주요 기능

- ✅ **포스트 관리**: CRUD (생성, 조회, 수정, 삭제)
- ✅ **사용자 관리**: 목록, 상세, 생성
- ✅ **댓글 관리**: 조회, 생성
- ✅ **앨범 및 사진**: 그리드 뷰, 이미지 로딩
- ✅ **네트워크 상태 모니터링**: 실시간 연결 상태 표시
- ✅ **에러 처리**: 사용자 친화적 메시지

## 🏗️ 아키텍처

- **MVVM**: View-ViewModel 분리
- **Repository Pattern**: 데이터 접근 추상화
- **UseCase Pattern**: 비즈니스 로직 캡슐화
- **Dependency Injection**: 의존성 주입

자세한 아키텍처 설계는 [ARCHITECTURE.md](./ARCHITECTURE.md)를 참고하세요.

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

## 📁 프로젝트 구조

```
AsyncNetworkSampleApp/
├── App/                    # 진입점, 의존성 주입
├── Presentation/           # SwiftUI Views + ViewModels
│   ├── Posts/
│   ├── Users/
│   ├── Comments/
│   ├── Albums/
│   └── Common/
├── Domain/                 # 비즈니스 로직
│   ├── Models/
│   ├── Repositories/
│   └── UseCases/
└── Data/                   # 네트워크 구현
    ├── Repositories/
    ├── API/
    └── Network/
```

## 🔌 AsyncNetwork 기능 활용

이 샘플 앱은 다음 AsyncNetwork 기능을 활용합니다:

- **@APIRequest 매크로**: API 요청 정의
- **Property Wrappers**: @QueryParameter, @PathParameter, @RequestBody, @HeaderField
- **RequestInterceptor**: 인증, 로깅
- **RetryPolicy**: 재시도 정책
- **NetworkMonitor**: 네트워크 상태 모니터링

## 📚 참고 자료

- [AsyncNetwork README](../../README.md)
- [아키텍처 설계](./ARCHITECTURE.md)
- [AsyncNetwork 사용 가이드](../../.cursor/rules/spec/asynchnetwork/RULE.mdc)

## 📄 라이선스

이 샘플 앱은 AsyncNetwork와 동일한 MIT License를 따릅니다.


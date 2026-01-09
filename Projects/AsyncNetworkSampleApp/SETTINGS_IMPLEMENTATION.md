# Settings 기능 구현 완료

## ✅ TDD로 구현된 기능

### Phase 1: Settings 탭 (완료)

#### 1. Settings 도메인 모델 ✅
- `NetworkConfigurationPreset`: 5가지 프리셋 (Development, Default, Stable, Fast, Test)
- `RetryPolicyPreset`: 3가지 재시도 정책 (Default, Aggressive, Conservative)
- `LoggingLevel`: 4가지 로깅 레벨 (Verbose, Info, Error, None)
- `NetworkStatus`: 연결 상태 및 타입 표현

**테스트**: `SettingsTests.swift` (10개 테스트)
- 모든 프리셋/레벨 열거
- displayName 및 description 검증
- 상태 값 정확성 검증

#### 2. SettingsViewModel (AsyncViewModel) ✅
- 단방향 데이터 흐름 구현
- Input → Action → Reduce → State 패턴
- AsyncEffect로 NetworkMonitor 통합
- 테스트 가능한 구조

**테스트**: `SettingsViewModelTests.swift` (12개 테스트)
- 초기 상태 검증
- Configuration/RetryPolicy/LoggingLevel 변경
- NetworkMonitor 상태 로드
- Reset to Defaults 기능

#### 3. NetworkMonitor 통합 ✅
- 실시간 네트워크 상태 감지
- 연결 타입 표시 (Wi-Fi, Cellular, Ethernet, etc.)
- isExpensive/isConstrained 플래그
- viewDidAppear/Disappear 생명주기 관리

**테스트**: `NetworkMonitorIntegrationTests.swift` (10개 테스트)
- 모든 연결 타입 처리
- 연결 해제 상태 처리
- Expensive/Constrained 플래그
- State 일관성 검증

#### 4. Settings UI (UITableViewController) ✅
- 섹션별 구성:
  - Network Status (읽기 전용)
  - Network Configuration (선택 가능)
  - Retry Policy (선택 가능)
  - Logging Level (선택 가능)
  - Reset to Defaults (확인 대화상자)
- Combine을 통한 반응형 UI 업데이트
- 선택 상태 표시 (Checkmark)

#### 5. MainTabBarController 통합 ✅
- Settings 탭 추가 (gear 아이콘)
- 4개 탭 구성: Posts, Users, Albums, Settings

---

## 📊 테스트 통계

- **도메인 모델 테스트**: 10개
- **ViewModel 테스트**: 12개
- **통합 테스트**: 10개
- **총 테스트**: 32개
- **빌드 상태**: ✅ 성공
- **린팅 에러**: 0개

---

## 🎯 주요 기능

### 1. Network Configuration 프리셋
- **Development**: 재시도 1회, 빠른 타임아웃 (15초)
- **Default**: 재시도 3회, 균형잡힌 타임아웃 (30초)
- **Stable**: 재시도 5회, 긴 타임아웃 (60초)
- **Fast**: 재시도 1회, 짧은 타임아웃 (10초)
- **Test**: 재시도 없음, 짧은 타임아웃 (5초)

### 2. Retry Policy 프리셋
- **Default**: 최대 3회, 1초 지연
- **Aggressive**: 최대 5회, 0.5초 지연
- **Conservative**: 최대 1회, 2초 지연

### 3. Logging Level
- **Verbose**: 모든 네트워크 로그 출력
- **Info**: 요청/응답 정보만 출력
- **Error**: 에러만 출력
- **None**: 로그 비활성화

### 4. Network Status 모니터링
- 실시간 연결 상태 (Connected/Disconnected)
- 연결 타입 (Wi-Fi/Cellular/Ethernet/Loopback/Unknown)
- Expensive 플래그 (셀룰러 데이터 등)
- Constrained 플래그 (저전력 모드 등)

---

## 🏗️ 아키텍처

### TDD 워크플로우

```
1. 테스트 작성 (Red)
   ├── SettingsTests.swift
   ├── SettingsViewModelTests.swift
   └── NetworkMonitorIntegrationTests.swift

2. 최소 구현 (Green)
   ├── Settings.swift (도메인 모델)
   ├── SettingsViewModel.swift (@AsyncViewModel)
   └── SettingsViewController.swift (UITableViewController)

3. 리팩토링 (Refactor)
   ├── DetailTableViewCell 추출
   ├── Section enum으로 구조화
   └── MockNetworkMonitor 재사용
```

### 단방향 데이터 흐름

```
User Action (UI)
    ↓
Input (viewDidAppear, configurationPresetSelected, etc.)
    ↓
transform() → [Action]
    ↓
reduce(state, action) → (State 변경, [AsyncEffect])
    ↓
@Published state 업데이트 → UI 자동 갱신
    ↓
AsyncEffect 실행 → 새로운 Action 생성 (순환)
```

---

## 📱 사용 방법

### 1. 앱 실행
```bash
cd Projects/AsyncNetworkSampleApp
tuist generate
open AsyncNetworkSampleApp.xcworkspace
```

### 2. Settings 탭 확인
- 4번째 탭 (gear 아이콘) 선택
- Network Status 섹션에서 현재 네트워크 상태 확인
- Configuration/RetryPolicy/LoggingLevel 변경
- Reset to Defaults로 초기화

### 3. 테스트 실행
```bash
swift test
# 또는
xcodebuild test -workspace AsyncNetworkSampleApp.xcworkspace -scheme AsyncNetworkSampleApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## 🚀 다음 단계 (Phase 2)

### Advanced Features (구현 예정)
1. **Error Simulator**: 네트워크 에러 시뮬레이션
2. **Retry Tester**: 재시도 로직 시각화
3. **Request Logger**: 요청/응답 로그 뷰어
4. **Custom Interceptor**: 사용자 정의 인터셉터
5. **Mock Response**: API Mock 응답 전환

---

## 📝 코드 예시

### ViewModel 사용
```swift
let viewModel = SettingsViewModel()

// Configuration 변경
viewModel.send(.configurationPresetSelected(.stable))

// State 관찰
viewModel.$state
    .sink { state in
        print("Current config: \(state.configurationPreset)")
    }
```

### 테스트 작성
```swift
@Test("Configuration 변경 시 State 업데이트")
func configurationChangeUpdatesState() async {
    let viewModel = SettingsViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    
    await store.send(.configurationPresetSelected(.stable)) { state in
        state.configurationPreset = .stable
    }
}
```

---

## 📚 참고 자료
- [AsyncViewModel Guide](../../.cursor/rules/spec/asyncviewmodel/RULE.mdc)
- [Swift Testing Guide](../../.cursor/rules/spec/swift-testing/RULE.mdc)
- [AsyncNetwork README](../../README.md)

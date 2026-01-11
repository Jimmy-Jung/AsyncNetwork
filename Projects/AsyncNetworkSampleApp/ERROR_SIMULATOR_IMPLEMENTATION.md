# Phase 2: Error Simulator 구현 완료

## ✅ TDD로 구현된 기능

### Phase 2-1: Error Simulator (완료)

#### 1. **ErrorSimulator 도메인 모델** ✅
**파일**: `Sources/Domain/Models/ErrorSimulator.swift`
- `SimulatedErrorType`: 7가지 에러 타입
  - none (정상)
  - networkConnectionLost (재시도 가능)
  - timeout (재시도 가능)
  - notFound (404)
  - serverError (500, 재시도 가능)
  - unauthorized (401)
  - badRequest (400)
- `ErrorSimulationResult`: 시뮬레이션 결과 표현
  - success: URL, 상태 코드, 소요 시간
  - failure: URL, 에러 타입, 시도 횟수, 재시도 여부, 소요 시간

**테스트**: `Tests/Domain/Models/ErrorSimulatorTests.swift` (8개 테스트)
- 모든 에러 타입 열거
- displayName 및 description 검증
- shouldRetry 플래그 검증
- ErrorSimulationResult 생성 및 표시

#### 2. **ErrorSimulatorViewModel (AsyncViewModel)** ✅
**파일**: `Sources/Presentation/Settings/ErrorSimulatorViewModel.swift`
- Input/Action/State/CancelID 타입 정의
- 단방향 데이터 흐름 구현
- 재시도 로직 시뮬레이션
  - 재시도 가능 에러: 최대 3회 재시도
  - 재시도 불가능 에러: 1회만 실패
  - 각 시도마다 결과 기록
- AsyncEffect로 비동기 시뮬레이션 처리
- Cancel 기능 지원

**테스트**: `Tests/Presentation/Settings/ErrorSimulatorViewModelTests.swift` (9개 테스트)
- 초기 상태 검증
- 에러 타입 선택
- 정상 케이스 시뮬레이션
- 재시도 로직 검증
- 시뮬레이션 취소

#### 3. **Error Simulator UI** ✅
**파일**: `Sources/Presentation/Settings/ErrorSimulatorViewController.swift`
- UITableViewController 기반
- 3개 섹션:
  - **에러 타입 선택**: 7가지 에러 타입 (아이콘 + 설명)
  - **동작**: 시작/취소, 결과 초기화
  - **시뮬레이션 결과**: 실시간 결과 표시
    - 성공: ✅ 상태 코드, 소요 시간
    - 실패: ❌ 에러 타입, 시도 횟수, 재시도 여부, 소요 시간
- Combine으로 반응형 UI 업데이트
- ResultTableViewCell: 커스텀 결과 셀

#### 4. **Settings 탭 통합** ✅
**파일**: `Sources/Presentation/Settings/SettingsViewController.swift`
- **개발자 도구** 섹션 추가
- Error Simulator 메뉴 아이템
  - 아이콘: 🔨 (hammer.circle.fill)
  - 설명: "네트워크 에러 시뮬레이션 및 재시도 테스트"
  - 탭 시 ErrorSimulatorViewController로 네비게이션

---

## 📊 Phase 2 통계

```
📁 구현 파일: 3개
  ├─ ErrorSimulator.swift (도메인 모델)
  ├─ ErrorSimulatorViewModel.swift (AsyncViewModel)
  └─ ErrorSimulatorViewController.swift (UITableViewController)

🧪 테스트 파일: 2개
  ├─ ErrorSimulatorTests.swift (8개 테스트)
  └─ ErrorSimulatorViewModelTests.swift (9개 테스트)

📈 총 테스트: 17개
✅ 빌드 상태: 성공
🚫 린팅 에러: 0개
```

---

## 🎯 Error Simulator 주요 기능

### 1. 에러 타입 시뮬레이션 (7가지)

| 에러 타입 | 아이콘 | 재시도 | 설명 |
|----------|--------|--------|------|
| 정상 | ✅ | ❌ | 정상 동작 - 에러 없음 |
| 네트워크 연결 끊김 | 📶 | ✅ | NetworkConnectionLost 시뮬레이션 |
| 타임아웃 | ⏰ | ✅ | Timeout 시뮬레이션 |
| 404 Not Found | ❓ | ❌ | 리소스 없음 |
| 500 Server Error | 🖥️ | ✅ | 서버 내부 에러 |
| 401 Unauthorized | 🔒 | ❌ | 인증 실패 |
| 400 Bad Request | ⚠️ | ❌ | 잘못된 요청 |

### 2. 재시도 로직 시뮬레이션

#### 재시도 가능 에러 (networkConnectionLost, timeout, serverError)
```
시도 1 → 실패 (재시도 예정) → 1초 대기
시도 2 → 실패 (재시도 예정) → 1초 대기
시도 3 → 실패 (재시도 예정) → 1초 대기
시도 4 → 실패 (재시도 불가)
```

#### 재시도 불가능 에러 (notFound, unauthorized, badRequest)
```
시도 1 → 실패 (재시도 불가)
```

### 3. 실시간 결과 표시

각 시도마다 결과가 실시간으로 표시됩니다:

**성공 케이스**:
```
✅ 성공 (HTTP 200, 0.12초)
https://jsonplaceholder.typicode.com/posts
```

**실패 케이스**:
```
❌ 실패 (타임아웃, 시도 1, 재시도 예정, 0.52초)
https://jsonplaceholder.typicode.com/posts

❌ 실패 (타임아웃, 시도 2, 재시도 예정, 0.51초)
https://jsonplaceholder.typicode.com/posts

❌ 실패 (타임아웃, 시도 3, 재시도 예정, 0.50초)
https://jsonplaceholder.typicode.com/posts

❌ 실패 (타임아웃, 시도 4, 재시도 불가, 0.53초)
https://jsonplaceholder.typicode.com/posts
```

---

## 🏗️ AsyncViewModel 아키텍처 적용

Error Simulator는 AsyncViewModel의 모든 패턴을 완벽하게 보여줍니다:

### 1. Input → Action 변환
```swift
enum Input {
    case errorTypeSelected(SimulatedErrorType)
    case startSimulationTapped
    case cancelSimulationTapped
    case clearResultsTapped
}
```

### 2. Action 처리
```swift
enum Action {
    case errorTypeChanged(SimulatedErrorType)
    case startSimulation
    case simulationResultReceived(ErrorSimulationResult)
    case simulationCompleted
}
```

### 3. State 관리
```swift
struct State {
    var selectedErrorType: SimulatedErrorType
    var isSimulating: Bool
    var results: [ErrorSimulationResult]
    var currentAttempt: Int
    var maxRetries: Int
}
```

### 4. AsyncEffect로 비동기 작업
```swift
.run(id: .simulation) {
    // 재시도 로직 시뮬레이션
    while attempt <= maxRetries {
        await .simulationAttempt(attempt)
        // 요청 시뮬레이션
        await .simulationResultReceived(result)
        // 재시도 지연
        try? await Task.sleep(...)
    }
}
```

### 5. Cancellable Effect
```swift
// 취소 버튼 탭 시
case .cancelSimulation:
    state.isSimulating = false
    return [.cancel(id: .simulation)]
```

---

## 📱 사용 방법

### 1. Settings 탭 진입
```
앱 실행 → Settings 탭 (4번째) → 개발자 도구 섹션 → Error Simulator
```

### 2. 에러 시뮬레이션
```
1. 에러 타입 선택 (예: 타임아웃)
2. "시뮬레이션 시작" 버튼 탭
3. 실시간으로 결과 확인
   - 시도 1: 실패 (재시도 예정)
   - 시도 2: 실패 (재시도 예정)
   - 시도 3: 실패 (재시도 예정)
   - 시도 4: 실패 (재시도 불가)
4. 결과 분석
```

### 3. 다른 에러 타입 테스트
```
1. "결과 초기화" 버튼으로 이전 결과 제거
2. 다른 에러 타입 선택
3. 재시도 로직 차이 확인
```

---

## 🎓 학습 포인트

### 1. TDD 워크플로우
- Red: 도메인 모델 테스트 → ViewModel 테스트 작성
- Green: 최소 구현으로 테스트 통과
- Refactor: UI 컴포넌트 추출 및 정리

### 2. AsyncViewModel 패턴
- 단방향 데이터 흐름의 완벽한 예시
- AsyncEffect로 복잡한 비동기 로직 처리
- Cancellable Effect로 사용자 제어

### 3. 재시도 로직 이해
- 재시도 가능/불가능 에러 구분
- 재시도 횟수 제한
- 재시도 간격 (Exponential Backoff 가능)

### 4. 실전 디버깅 도구
- 네트워크 에러 상황 시뮬레이션
- RetryPolicy 동작 시각화
- 실제 API 호출 없이 테스트

---

## 🚀 다음 확장 가능성

### Phase 2-2: Request Logger (예정)
- 실제 네트워크 요청 로깅
- Request/Response 상세 정보
- 필터링 및 검색

### Phase 2-3: Retry Visualizer (예정)
- 재시도 타임라인 차트
- Exponential Backoff 시각화
- Jitter 효과 표시

### Phase 2-4: Custom Interceptor (예정)
- 사용자 정의 인터셉터 추가
- Request/Response 수정
- 메트릭 수집

---

## 📚 참고 자료
- [AsyncViewModel Guide](../../.cursor/rules/spec/asyncviewmodel/RULE.mdc)
- [Swift Testing Guide](../../.cursor/rules/spec/swift-testing/RULE.mdc)
- [Settings Implementation](SETTINGS_IMPLEMENTATION.md)
- [Architecture](ARCHITECTURE.md)

---

## 🎉 Phase 2 완료!

AsyncNetwork의 **Error Simulator**가 완성되었습니다!

- ✅ 7가지 에러 타입 시뮬레이션
- ✅ 재시도 로직 시각화
- ✅ 실시간 결과 표시
- ✅ AsyncViewModel 패턴 완벽 적용
- ✅ 모든 테스트 통과

이제 개발자들은 Settings 탭에서 **Error Simulator**를 사용하여 AsyncNetwork의 재시도 정책과 에러 처리를 직접 테스트하고 학습할 수 있습니다! 🎊

# TCA 철학: 왜 결정론적 테스트인가?

## 🎯 핵심 질문

> "왜 AsyncNetwork v2.0은 랜덤 값 생성에 Seed를 사용하는가?"

## 📖 The Composable Architecture (TCA)의 철학

### 1. 결정론적 실행 (Deterministic Execution)

TCA는 **모든 부수 효과(Side Effects)를 제어 가능하게** 만드는 것을 핵심 원칙으로 삼습니다.

```swift
// ❌ 제어 불가능한 부수 효과
let now = Date()           // 실행 시마다 다른 값
let uuid = UUID()          // 실행 시마다 다른 값
let random = Int.random()  // 실행 시마다 다른 값
```

**문제점:**
- 테스트가 실행 시간에 의존
- 재현 불가능한 버그 (Flaky Tests)
- CI/CD에서 간헐적 실패

**TCA 해결책:**
```swift
// ✅ 제어 가능한 의존성
@Dependency(\.date) var date      // 테스트에서 고정 가능
@Dependency(\.uuid) var uuid      // 테스트에서 고정 가능
@Dependency(\.rng) var rng        // 테스트에서 Seed로 제어
```

## 🔬 AsyncNetwork v2.0의 접근

### Before v1.x: 제어 불가능한 랜덤

```swift
@ResponseTestable
struct UserDTO: Codable {
    let id: Int
    let name: String
}

// ❌ 실행할 때마다 다른 값
let user1 = UserDTO.mock()       // id: 12345, name: "abcde"
let user2 = UserDTO.mock()       // id: 67890, name: "fghij"
let users = UserDTO.mockArray()  // [random, random, ...]

// 테스트가 깨질 수 있음
XCTAssertEqual(user1.id, 12345)  // ❌ 다음 실행에서 실패
```

**문제:**
- 같은 테스트를 두 번 실행하면 다른 결과
- 버그를 재현하려면 운에 의존
- CI에서 간헐적으로 실패

### After v2.0: Seed 기반 결정론적 랜덤

```swift
@ResponseTestable
struct UserDTO: Codable {
    let id: Int
    let name: String
}

// ✅ Seed가 같으면 항상 같은 값
let user1 = UserDTO.random(seed: 42)
let user2 = UserDTO.random(seed: 42)

XCTAssertEqual(user1.id, user2.id)      // ✅ 항상 통과
XCTAssertEqual(user1.name, user2.name)  // ✅ 항상 통과
```

**장점:**
- **재현 가능**: 같은 Seed = 같은 결과
- **디버깅 용이**: 버그가 발생한 Seed를 기록하면 재현 가능
- **CI 안정성**: Flaky Test 제거

## 🧪 실전 예제

### 시나리오: 복잡한 데이터 구조 테스트

```swift
struct Order: Codable {
    let id: Int
    let items: [OrderItem]
    let total: Decimal
    let createdAt: Date
}

struct OrderItem: Codable {
    let productId: Int
    let quantity: Int
    let price: Decimal
}
```

### v1.x 방식 (문제가 많음)

```swift
func testOrderCalculation() {
    let order = Order.mock()
    
    // ❌ items 개수가 매번 달라짐 (0~10개 랜덤)
    // ❌ total이 items와 일치하지 않을 수 있음
    // ❌ 테스트 실패 시 재현 불가능
    
    let calculatedTotal = order.items.reduce(0) { 
        $0 + ($1.price * Decimal($1.quantity)) 
    }
    
    XCTAssertEqual(order.total, calculatedTotal)  // ❌ 간헐적 실패
}
```

### v2.0 방식 (안정적)

```swift
func testOrderCalculation() {
    // ✅ Seed를 고정하면 항상 같은 데이터
    let order = Order.random(seed: 100)
    
    print("Seed 100:")
    print("  Items: \(order.items.count)")  // 항상 같은 개수
    print("  Total: \(order.total)")         // 항상 같은 값
    
    let calculatedTotal = order.items.reduce(0) { 
        $0 + ($1.price * Decimal($1.quantity)) 
    }
    
    XCTAssertEqual(order.total, calculatedTotal)  // ✅ 항상 통과
    
    // 버그 발견 시 Seed를 기록하면 재현 가능
    // "Seed 100에서 실패" → 다른 개발자도 즉시 재현
}
```

## 🎲 Seed의 이해

### Seed란?

Seed는 랜덤 생성기의 **시작점**입니다. 같은 Seed에서 시작하면 항상 같은 순서로 "랜덤" 값을 생성합니다.

```swift
// Seed = 42
var rng = SeededRandomNumberGenerator(seed: 42)
print(Int.random(in: 1...100, using: &rng))  // 57
print(Int.random(in: 1...100, using: &rng))  // 23
print(Int.random(in: 1...100, using: &rng))  // 89

// 다시 Seed = 42로 초기화
var rng2 = SeededRandomNumberGenerator(seed: 42)
print(Int.random(in: 1...100, using: &rng2))  // 57 (같음!)
print(Int.random(in: 1...100, using: &rng2))  // 23 (같음!)
print(Int.random(in: 1...100, using: &rng2))  // 89 (같음!)
```

### 언제 Seed를 사용하는가?

| 상황 | Seed 사용 | 이유 |
|------|----------|------|
| 단위 테스트 | ✅ 필수 | 결정론적 검증 |
| 통합 테스트 | ✅ 권장 | 재현 가능한 시나리오 |
| UI 프리뷰 | ✅ 권장 | 일관된 미리보기 |
| 개발 중 디버깅 | ✅ 권장 | 버그 재현 |
| 프로덕션 코드 | ❌ 불필요 | 실제 랜덤 사용 |

## 🔍 TCA의 다른 결정론적 기법

### 1. TestClock (시간 제어)

```swift
// ❌ 제어 불가능
func testDebounce() async {
    await viewModel.search("test")
    try await Task.sleep(for: .seconds(0.5))  // 실제로 0.5초 대기
    XCTAssertEqual(viewModel.results.count, 1)
}

// ✅ 가상 시간 제어
func testDebounce() async {
    let clock = TestClock()
    let viewModel = ViewModel(clock: clock)
    
    await viewModel.search("test")
    await clock.advance(by: .seconds(0.5))  // 즉시 0.5초 "경과"
    XCTAssertEqual(viewModel.results.count, 1)
}
```

### 2. TestStore (Effect 제어)

```swift
// ✅ Effect를 하나씩 검증
let store = TestStore(initialState: State()) {
    MyFeature()
}

await store.send(.buttonTapped) {
    $0.isLoading = true
}

await store.receive(.response(.success(user))) {
    $0.isLoading = false
    $0.user = user
}
```

## 📊 결정론적 테스트의 이점

### 1. 재현 가능성

```swift
// 버그 리포트
"Seed 12345에서 OrderCalculation 테스트 실패"

// 다른 개발자가 즉시 재현
let order = Order.random(seed: 12345)
// 버그 발견 및 수정
```

### 2. 디버깅 효율

```swift
// 문제가 되는 Seed를 찾으면
for seed in 1...1000 {
    let data = MyDTO.random(seed: seed)
    if hasIssue(data) {
        print("문제 발견: Seed \(seed)")
        break
    }
}
```

### 3. CI/CD 안정성

```swift
// ❌ Flaky Test
Test Suite 'MyTests' failed (1 of 5 tests failed)

// ✅ 안정적인 테스트 (Seed 사용)
Test Suite 'MyTests' passed (5 of 5 tests passed)
```

## 🎓 학습 자료

### TCA 공식 문서
- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
- [Testing](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/testing/)

### Point-Free 비디오
- [Dependency Management](https://www.pointfree.co/collections/dependencies)
- [Composable Architecture](https://www.pointfree.co/collections/composable-architecture)

## 💡 핵심 원칙

1. **부수 효과는 명시적으로** - Date, UUID, Random은 의존성으로 주입
2. **테스트는 결정론적으로** - 같은 입력 = 같은 출력
3. **재현은 쉽게** - Seed, 고정된 시간, 고정된 UUID

---

> "Deterministic tests are not just about passing consistently—they're about making bugs reproducible, debugging efficient, and code maintainable."
> 
> — Point-Free Team

**작성자:** Jimmy Jung  
**날짜:** 2026-02-04  
**참고:** The Composable Architecture Philosophy

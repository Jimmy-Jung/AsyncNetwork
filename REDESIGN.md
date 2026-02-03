---
description: AsyncNetworkMacros 재설계 사양서 - 비판적 검토 결과를 바탕으로 한 개선안
author: Jimmy Jung
date: 2026-02-03
version: 2.1.0
status: DRAFT
---

# 🔄 AsyncNetworkMacros 재설계 사양서 v2.1

## 📋 문서 개요

본 문서는 AsyncNetworkMacros v1.x에 대한 비판적 검토 결과와 **TCA(The Composable Architecture)** 의 테스트 철학(결정론적 테스트, 철저한 검증)을 반영하여 v2.0 재설계 사양을 정의합니다.

### 현재 버전 문제점 요약

| 항목 | 현재 점수 | 목표 점수 | 주요 문제 |
|------|-----------|-----------|----------|
| 아키텍처 | 3/10 | 8/10 | 과잉 설계, 불필요한 계층화 |
| 사용성 | 7/10 | 9/10 | 제약이 많고 커스터마이징 어려움 |
| 안정성 | 5/10 | **10/10** | 랜덤 값으로 인한 테스트 불안정 (Flaky Tests) |
| 확장성 | 4/10 | 8/10 | 하드코딩된 값, 설정 불가 |
| 문서화 | 6/10 | 9/10 | 과잉과 부족의 공존 |
| 에러 처리 | 4/10 | 9/10 | 불친절한 메시지, 해결책 부재 |

---

## 🎯 재설계 목표

### 핵심 원칙

1. **단순성 (Simplicity)**: 복잡도를 1/3로 줄이고 평탄한 구조
2. **명확성 (Clarity)**: 이름만 봐도 동작을 알 수 있게 (`mock` → `random/fixture`)
3. **결정론적 안정성 (Deterministic Stability)**: **TCA 철학 반영** - 모든 테스트와 랜덤 생성은 제어 가능해야 함
4. **확장성 (Extensibility)**: 사용자가 쉽게 커스터마이징
5. **친절함 (Kindness)**: 자세한 에러 메시지와 해결책 제시

### 개선 목표

- 파일 수: 35개 → 12~15개 (60% 이상 감소)
- 계층 깊이: 4단계 → 2단계
- **테스트 전략**: 단순 단위 테스트 → **스냅샷 기반 매크로 테스트** (`swift-macro-testing` 도입)
- **테스트 데이터**: 통제 불가능한 랜덤 → **Seed 기반의 재현 가능한 랜덤**
- 에러 메시지: 1줄 → 해결책 포함 5줄 (Fix-it 제공)

---

## 📁 새로운 아키텍처

### v1.x (현재) - 과잉 설계

```
AsyncNetworkMacros/
├── Domain/              # ❌ 매크로에 "비즈니스 로직" 개념 부적절
│   ├── Models/
│   ├── Parsers/
│   └── Generators/
├── Infrastructure/      # ❌ 추상화 과다
├── MacroImplementations/
└── Facade/              # ❌ 불필요한 레이어
```

### v2.0 (제안) - 단순하고 평탄한 구조

```
AsyncNetworkMacros/
├── Core/
│   ├── MacroDefinitions.swift       # 외부 공개 매크로 선언
│   └── Diagnostic/                  # 에러 처리 모듈화
│       ├── MacroError.swift         # 에러 열거형 및 메시지
│       ├── DiagnosticMessage+FixIt.swift # FixIt 생성 로직
│       └── ValidationLevel.swift    # 검증 레벨 정의
│
├── APIRequest/
│   ├── APIRequestMacro.swift        # 진입점
│   ├── APIRequestExpansion.swift    # 실제 확장 로직 (Extension)
│   ├── APIRequestValidator.swift    # 유효성 검증
│   └── Generators/                  # 생성 로직
│       └── RequestPropertyGenerator.swift
│
├── ResponseTestable/
│   ├── ResponseTestableMacro.swift  # 진입점
│   ├── ResponseTestableExpansion.swift
│   ├── Strategies/                  # 전략 패턴 구현체
│   │   ├── RandomStrategy.swift     # ✨ Seed 지원 필수
│   │   └── FixtureStrategy.swift
│   ├── Generators/
│   │   ├── ValueGenerator.swift     # 값 생성 로직
│   │   └── BuilderGenerator.swift   # Builder 구조체 생성 로직
│   └── Utils/
│       └── CircularReferenceDetector.swift # 순환 참조 감지
│
├── Shared/
│   ├── SyntaxHelpers.swift          # SwiftSyntax 편의 기능
│   └── TypeAnalyzer.swift           # 타입 분석 유틸리티
│
└── Plugin/
    └── AsyncNetworkMacrosPlugin.swift  # 컴파일러 플러그인
```

---

## 🔧 매크로별 재설계

### 1. @APIRequest 매크로

(이전 버전과 동일: 동적 메서드 지원, 검증 레벨 설정, 코드 생성 옵션)

### 2. @ResponseTestable 매크로 (TCA 철학 반영)

#### TCA 관점에서의 문제점
TCA는 테스트의 **결정론적 실행(Deterministic Execution)** 을 매우 중요하게 여깁니다. (`withDependencies`로 날짜, UUID 등을 통제).
현재의 `random()`은 실행할 때마다 결과가 달라져 "깨지기 쉬운 테스트(Flaky Test)"를 유발할 수 있습니다.

#### 재설계 사양

##### 2.1 명확한 네이밍

```swift
// ✅ v2.0 - 명확한 네이밍
let user = UserDTO.random()         // 랜덤 (기본)
let user = UserDTO.fixture()        // 고정값 (기본값)
```

##### 2.2 전략 패턴 도입 (Seed 지원 추가)

```swift
// v2.0: 생성 전략 선택 가능
@ResponseTestable(
    strategy: .random(
        optionals: .random,
        arrayCount: 2...5,
        seed: 1234  // ✨ TCA 스타일: Seed를 고정하여 항상 같은 랜덤 값 생성 보장
    )
)
struct UserDTO: Codable, Sendable { ... }

@ResponseTestable(
    strategy: .fixture(
        optionals: .alwaysPresent,
        arrayCount: 3,
        enumStrategy: .firstCase
    )
)
struct PostDTO: Codable, Sendable { ... }
```

##### 2.3 생성된 API (시드 제어 포함)

```swift
extension UserDTO {
    // 랜덤 생성 (매개변수로 시드 제어 가능)
    static func random(seed: Int? = nil) -> UserDTO
    
    // 고정값 생성 (Fixture)
    static func fixture() -> UserDTOFixtureBuilder
    
    // 검증 (Exhaustive Check)
    func assertValid() throws
}
```

---

## 🧪 테스트 전략 개선 (TCA/Point-Free 스타일)

### v1.x (현재) - 단순 단위 테스트
매크로가 생성한 코드 문자열을 하드코딩하여 비교하는 방식은 유지보수가 어렵고 가독성이 떨어집니다.

### v2.0 (제안) - 스냅샷 기반 매크로 테스트 (`swift-macro-testing`)

TCA 팀(Point-Free)에서 개발한 `swift-macro-testing` 라이브러리를 도입하여, 매크로 확장 결과를 **스냅샷**으로 검증합니다.

#### 1. 매크로 확장 테스트 (Expansion Test)

```swift
import MacroTesting
import XCTest
import AsyncNetworkMacros

final class APIRequestMacroTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            // 매크로 등록
            macros: [APIRequestMacro.self]
        ) {
            super.invokeTest()
        }
    }

    func testAPIRequestExpansion() {
        // ✨ 입력 코드와 예상되는 확장 결과를 스냅샷처럼 비교
        assertMacro {
            """
            @APIRequest(response: User.self, baseURL: "...", path: "/me", method: .get)
            struct GetMeRequest {}
            """
        } expansion: {
            """
            struct GetMeRequest {
                var baseURLString: String { "..." }
                var path: String { "/me" }
                var method: HTTPMethod { .get }
                typealias Response = User
            }
            
            extension GetMeRequest: APIRequest {}
            """
        }
    }
}
```

#### 2. 에러 진단 테스트 (Diagnostic Test)

Fix-it이 올바르게 제안되는지 검증합니다.

```swift
func testStructValidation() {
    assertMacro {
        """
        @APIRequest(...)
        class MyRequest {} // ❌ class 사용
        """
    } diagnostics: {
        """
        @APIRequest(...)
        class MyRequest {}
        ┬───
        ╰─ ❌ @APIRequest는 struct에만 적용할 수 있습니다
           ✏️ struct로 변경
        """
    } fixes: {
        """
        @APIRequest(...)
        struct MyRequest {} // ✅ Fix-it 적용 결과 검증
        """
    }
}
```

#### 3. 런타임 결정론적 테스트 (Deterministic Runtime Test)

`ValueGenerator`가 시드(Seed)에 따라 항상 동일한 값을 생성하는지 검증합니다.

```swift
func testDeterministicRandomness() {
    // Seed가 같으면 결과도 같아야 함 (TCA 철학)
    let user1 = UserDTO.random(seed: 42)
    let user2 = UserDTO.random(seed: 42)
    
    XCTAssertEqual(user1, user2, "동일한 시드에서는 동일한 랜덤 값이 생성되어야 합니다.")
    
    // Seed가 다르면 결과도 달라야 함
    let user3 = UserDTO.random(seed: 999)
    XCTAssertNotEqual(user1, user3)
}
```

---

## 📊 ValueGenerator 개선

### v2.0 (제안) - 의존성 주입 가능 구조

TCA의 `Dependency` 시스템처럼, 내부 난수 생성기(RNG)를 교체할 수 있도록 설계합니다.

```swift
public protocol ValueGenerationStrategy {
    // ... 메서드 정의 ...
}

public struct RandomStrategy: ValueGenerationStrategy {
    private var generator: any RandomNumberGenerator
    
    public init(seed: Int? = nil) {
        if let seed = seed {
            // 시드가 있으면 결정론적 생성기 사용
            self.generator = SeededRandomNumberGenerator(seed: seed)
        } else {
            // 없으면 시스템 랜덤 사용
            self.generator = SystemRandomNumberGenerator()
        }
    }
    
    public mutating func generateInt() -> Int {
        return Int.random(in: intRange, using: &generator)
    }
}
```

---

## 🎯 구현 우선순위

### Phase 1: 핵심 개선 (v2.0.0-alpha)
- [ ] **파일 구조 재구성**: `Core`, `APIRequest`, `ResponseTestable` 구조로 재배치.
- [ ] **테스트 환경 구축**: `swift-macro-testing` 라이브러리 의존성 추가 및 기본 테스트 셋업.
- [ ] **네이밍 변경**: `mock` → `random`, `builder` → `fixture`.

### Phase 2: 전략 패턴 및 안정성 (v2.0.0-beta)
- [x] **RandomStrategy (Seeded)**: 시드 기반 난수 생성기 구현.
- [x] **FixtureStrategy (Enum Support)**: Enum 기본값 처리 전략 구현.
- [x] **순환 참조 감지**: 재귀 깊이 제한 로직.

### Phase 3: 확장 기능 (v2.0.0-rc)
- [ ] **@APIRequest 확장**: 동적 메서드, 검증 레벨.
- [ ] **에러 처리 고도화**: 상세 메시지 및 Fix-it 구현.

### Phase 4: 안정화 (v2.0.0)
- [ ] **마이그레이션 도구**: SwiftSyntax 기반 자동 변환 스크립트.
- [ ] **공식 문서**: TCA 스타일의 철학("Why Deterministic?") 설명 포함.

---

## 📊 성공 지표

| 지표 | v1.x | v2.0 목표 |
|------|------|-----------|
| 파일 수 | 35개 | **12~15개** |
| 테스트 방식 | 문자열 비교 | **Macro Snapshot (`assertMacro`)** |
| 테스트 안정성 | 랜덤 (불안정) | **Seed 기반 결정론적 (100% 재현 가능)** |
| Enum 지원 | 제한적 | **전용 전략 제공** |
| 에러 메시지 | 1줄 | **5줄 (Fix-it 포함)** |

---

## 📝 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 2.0.0 | 2026-02-03 | 아키텍처 구조 구체화, Enum 전략 추가 |
| 2.1.0 | 2026-02-03 | **TCA 테스트 철학 반영** (`swift-macro-testing` 도입, Seed 기반 랜덤 전략) |

---

**문서 작성:** Jimmy Jung  
**최종 수정:** 2026-02-03  
**상태:** 승인됨 (Approved)

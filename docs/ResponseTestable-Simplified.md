# @ResponseTestable 매크로 - 극도로 간소화 (v1.3.1)

## 개요

`@ResponseTestable` 매크로가 극도로 간소화되어 **대부분의 경우 파라미터 없이 사용**합니다.
- **Builder 항상 제공**: `includeBuilder` 파라미터 제거
- **fixture() 제거**: 복잡한 fixtureJSON 검증 제거
- **최소 설정**: 기본값으로 모든 기능 제공

## 변경 사항 요약

### Before (v1.2.0)

```swift
@ResponseTestable(
    fixtureJSON: """
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
    """,
    includeBuilder: true,
    defaultArrayCount: 5,
    generateDocumentation: true
)
struct UserDTO: Codable, Sendable {
    let id: Int
    let name: String
    let email: String
}
```

### After (v1.3.1)

```swift
@ResponseTestable
struct UserDTO: Codable, Sendable {
    let id: Int
    let name: String
    let email: String
}

// 또는 배열 개수만 커스터마이징
@ResponseTestable(defaultArrayCount: 10)
struct ProductDTO: Codable, Sendable {
    let id: String
}
```

## 파라미터

| 파라미터 | 타입 | 기본값 | 필수 | 설명 |
|---------|------|-------|-----|------|
| `defaultArrayCount` | Int | `5` | ❌ | mockArray() 기본 개수 |

**제거된 파라미터:**
- `includeBuilder` - Builder는 항상 제공됨 ✅
- `fixtureJSON` - 제거됨
- `generateDocumentation` - 제거됨

## 사용 패턴

### Pattern 1: 기본 사용 (권장)

99%의 경우 파라미터 없이 사용합니다.

```swift
@ResponseTestable
struct UserDTO: Codable, Sendable {
    let id: Int
    let name: String
    let email: String
}

// 모든 기능 자동 제공
let user = UserDTO.mock()
let users = UserDTO.mockArray()  // 5개 생성
let custom = UserDTO.builder()
    .with(id: 1)
    .build()
```

### Pattern 2: 배열 개수 커스터마이징

```swift
@ResponseTestable(defaultArrayCount: 10)
struct ProductDTO: Codable, Sendable {
    let id: String
    let name: String
}

let products = ProductDTO.mockArray()  // 10개 생성
```

### Pattern 3: 완전 랜덤 (테스트 독립성)

```swift
@Test("랜덤 데이터로 비즈니스 로직 테스트")
func testRandomData() {
    let user = UserDTO.mock()
    #expect(user.id > 0)
    user.assertValid()
}
```

### Pattern 4: 특정 시나리오 (Builder로 고정)

```swift
@Test("관리자 계정 로직 테스트")
func testAdminScenario() {
    let admin = UserDTO.builder()
        .with(id: 1)
        .with(name: "Admin")
        .with(email: "admin@example.com")
        .build()
    
    #expect(admin.id == 1)
    admin.assertValid()
}
```

### Pattern 5: 부분 고정 (하이브리드)

```swift
@Test("특정 ID로만 테스트")
func testWithFixedId() {
    // id만 고정, 나머지는 랜덤
    let user = UserDTO.builder()
        .with(id: 999)
        .build()
    
    #expect(user.id == 999)
    #expect(!user.name.isEmpty)  // 랜덤 값
}
```

## 중첩 DTO 처리

중첩된 DTO는 자동으로 `.mock()`을 호출합니다.

```swift
@ResponseTestable
struct PostDTO: Codable, Sendable {
    let id: Int
    let title: String
    let author: UserDTO  // 자동으로 UserDTO.mock() 호출
    let comments: [CommentDTO]  // 자동으로 2~5개의 CommentDTO.mock() 생성
}

// 사용
let post = PostDTO.mock()
// post.author는 자동으로 랜덤 UserDTO
// post.comments는 자동으로 2~5개의 랜덤 CommentDTO
```

## 생성되는 API

```swift
@ResponseTestable
struct UserDTO: Codable, Sendable {
    let id: Int
    let name: String
}

// 자동 생성:
// - static func mock() -> Self
// - static func mockArray(count: Int = 5) -> [Self]
// - func assertValid()
// - static func builder() -> UserDTOBuilder
// - struct UserDTOBuilder { ... }
```

## 마이그레이션 가이드

### v1.3.0 → v1.3.1

#### 1. fixtureJSON 제거

**Before:**
```swift
@ResponseTestable(
    fixtureJSON: """{ "id": 1, "name": "Test" }""",
    includeBuilder: true
)
```

**After:**
```swift
@ResponseTestable
```

#### 2. includeBuilder 제거

**Before:**
```swift
@ResponseTestable(includeBuilder: true)
@ResponseTestable(includeBuilder: true, defaultArrayCount: 10)
```

**After:**
```swift
@ResponseTestable
@ResponseTestable(defaultArrayCount: 10)
```

#### 3. fixture() 사용 코드 변경

**Before:**
```swift
let user = UserDTO.fixture()
#expect(user.id == 1)
```

**After:**
```swift
let user = UserDTO.builder()
    .with(id: 1)
    .build()
#expect(user.id == 1)
```

## 장점

1. **극도의 단순성**: 대부분 `@ResponseTestable`만 작성
2. **Builder 항상 제공**: 설정 불필요
3. **유연성**: Builder가 mock 기반이므로 랜덤+고정 혼합 가능
4. **안정성**: fixtureJSON 검증 오류 제거
5. **성능**: 복잡한 JSON 검증 로직 제거
6. **유지보수**: 중첩 DTO 처리 자동화

## 참고

- AsyncNetwork 버전: v1.3.1+
- 매크로 구현: `ResponseTestableMacroImpl.swift`
- 테스트 예제: `Projects/AsyncNetworkSampleApp/Tests/Data/DTOs/`

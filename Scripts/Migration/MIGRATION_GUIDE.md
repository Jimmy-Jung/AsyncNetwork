# AsyncNetwork v1.x → v2.0 마이그레이션 가이드

## 📋 개요

AsyncNetwork v2.0은 TCA 철학을 반영하여 더 명확하고 결정론적인 API를 제공합니다.
이 가이드는 v1.x 코드를 v2.0으로 안전하게 마이그레이션하는 방법을 설명합니다.

## 🔄 주요 변경사항

### 1. @ResponseTestable 매크로 단순화

**v1.x (복잡함):**
```swift
@ResponseTestable(
    sampleData: [/* ... */],          // ❌ 제거됨
    alternativeSamples: [/* ... */],  // ❌ 제거됨
    fixtureJSON: "user.json",         // ❌ 제거됨
    defaultArrayCount: 3              // ❌ 제거됨
)
struct UserDTO: Codable, Sendable {
    let id: Int
    let name: String
}
```

**v2.0 (단순함):**
```swift
@ResponseTestable  // ✅ 파라미터 불필요
struct UserDTO: Codable, Sendable {
    let id: Int
    let name: String
}
```

**이유:**
- 과도한 설정 제거
- 매크로가 자동으로 최적의 값 생성
- Seed를 통한 결정론적 제어로 충분

### 2. 명확한 메서드 네이밍

**v1.x (모호함):**
```swift
let user = UserDTO.mock()      // ❌ "mock"은 의미가 불명확
let builder = UserDTO.builder() // ❌ "builder"는 패턴명일 뿐
```

**v2.0 (명확함):**
```swift
let user = UserDTO.random()           // ✅ 랜덤 값 생성
let user = UserDTO.random(seed: 42)   // ✅ Seed 기반 결정론적 랜덤
let builder = UserDTO.fixture()       // ✅ 고정값 빌더 반환
```

**이유:**
- `random()`: 의도가 명확 (무작위 값)
- `fixture()`: 테스트 픽스처 의미 명확
- Seed 파라미터로 TCA 스타일 결정론적 테스트 지원

### 3. Fixture 빌더 패턴

**v1.x:**
```swift
let user = UserDTO.builder()
    .id(123)
    .name("Alice")
    .build()
```

**v2.0:**
```swift
let user = UserDTO.fixture()
    .id(123)
    .name("Alice")
    .build()
```

**변경:**
- 메서드 이름만 변경
- 사용법은 동일

## 🛠️ 자동 마이그레이션 도구

### 설치

#### 방법 1: 간단한 스크립트 (추천)

```bash
# 스크립트를 실행 가능하게 만들기
chmod +x Scripts/Migration/migrate.swift

# 사용
./Scripts/Migration/migrate.swift <파일-또는-디렉토리>
```

#### 방법 2: SwiftSyntax 기반 고급 도구

```bash
cd Scripts/Migration
swift build -c release

# 설치 (선택)
cp .build/release/migrate-async-network /usr/local/bin/

# 사용
migrate-async-network <파일-또는-디렉토리>
```

### 사용법

#### 단일 파일 마이그레이션

```bash
./Scripts/Migration/migrate.swift Models/UserDTO.swift
```

#### 디렉토리 전체 마이그레이션

```bash
./Scripts/Migration/migrate.swift MyProject/Sources/
```

#### 고급 옵션 (SwiftSyntax 도구)

```bash
# Dry-run: 변경사항만 확인
migrate-async-network --dry-run MyProject/Sources/

# 백업 없이 마이그레이션
migrate-async-network --no-backup MyProject/Sources/

# 자세한 출력
migrate-async-network --verbose MyProject/Sources/
```

### 출력 예시

```
📁 디렉토리 마이그레이션: MyProject/Sources/
📝 발견된 Swift 파일: 15개

🔄 MyProject/Sources/Models/UserDTO.swift
  ✏️  @ResponseTestable: 제거된 파라미터 - sampleData, fixtureJSON
  ✏️  .mock() → .random()
  ✏️  .mockArray() → .randomArray()
  ✏️  .builder() → .fixture()
  ✅ 저장됨 (백업: UserDTO.swift.v1.backup)

⏭️  MyProject/Sources/Models/PostDTO.swift (변경사항 없음)

═══════════════════════════════════════
📊 마이그레이션 요약
═══════════════════════════════════════
✅ 변환됨: 12개
⏭️  건너뜀: 3개
═══════════════════════════════════════
```

## 📝 수동 마이그레이션

자동 도구가 모든 경우를 처리하지 못할 수 있습니다. 다음은 수동 마이그레이션 체크리스트입니다.

### 1. @ResponseTestable 정리

**Before:**
```swift
@ResponseTestable(
    sampleData: [
        UserDTO(id: 1, name: "Alice"),
        UserDTO(id: 2, name: "Bob")
    ],
    defaultArrayCount: 5
)
struct UserDTO: Codable, Sendable { ... }
```

**After:**
```swift
@ResponseTestable
struct UserDTO: Codable, Sendable { ... }
```

### 2. 테스트 코드 업데이트

**Before:**
```swift
func testUserDecoding() {
    let user = UserDTO.mock()
    let users = UserDTO.mockArray(count: 10)
    XCTAssertNotNil(user.id)
}
```

**After (TCA 스타일):**
```swift
func testUserDecoding() {
    // Seed를 고정하여 결정론적 테스트
    let user = UserDTO.random(seed: 42)
    let users = UserDTO.randomArray(count: 10, seed: 42)
    
    // 같은 Seed는 항상 같은 값 생성
    let user2 = UserDTO.random(seed: 42)
    XCTAssertEqual(user.id, user2.id)
}
```

### 3. Fixture 사용

**Before:**
```swift
let testUser = UserDTO.builder()
    .id(999)
    .name("Test User")
    .build()
```

**After:**
```swift
let testUser = UserDTO.fixture()
    .id(999)
    .name("Test User")
    .build()
```

## ⚠️ 주의사항

### 1. 백업 확인

자동 도구는 `.v1.backup` 확장자로 원본 파일을 백업합니다.

```bash
# 백업 파일 확인
find . -name "*.v1.backup"

# 백업 파일 삭제 (마이그레이션 검증 후)
find . -name "*.v1.backup" -delete
```

### 2. 빌드 테스트

마이그레이션 후 반드시 빌드와 테스트를 실행하세요.

```bash
swift build
swift test
```

### 3. Git 커밋

마이그레이션 전후로 별도 커밋을 만드는 것을 권장합니다.

```bash
# 마이그레이션 전
git commit -m "chore: backup before AsyncNetwork v2.0 migration"

# 마이그레이션 실행
./Scripts/Migration/migrate.swift Sources/

# 마이그레이션 후
git add .
git commit -m "refactor: migrate to AsyncNetwork v2.0"
```

## 🆘 문제 해결

### 문제: 마이그레이션 도구가 실행되지 않음

**해결:**
```bash
# 실행 권한 부여
chmod +x Scripts/Migration/migrate.swift

# Swift 버전 확인 (5.9 이상 필요)
swift --version
```

### 문제: 일부 파일만 변환됨

**원인:** v1.x 패턴이 없는 파일은 자동으로 건너뜁니다.

**확인:**
```bash
# v1.x 패턴 검색
grep -r "@ResponseTestable" Sources/
grep -r ".mock()" Sources/
grep -r ".builder()" Sources/
```

### 문제: 빌드 에러 발생

**해결:**
1. 백업 파일에서 복원: `cp file.swift.v1.backup file.swift`
2. 해당 파일을 수동으로 마이그레이션
3. 에러 로그를 확인하여 누락된 변경사항 찾기

## 📊 마이그레이션 체크리스트

- [ ] 프로젝트 백업 (Git 커밋 또는 전체 복사)
- [ ] 마이그레이션 도구 실행
- [ ] 빌드 성공 확인 (`swift build`)
- [ ] 테스트 통과 확인 (`swift test`)
- [ ] 백업 파일 정리
- [ ] Git 커밋

## 🎓 더 알아보기

- [REDESIGN.md](../../REDESIGN.md): v2.0 재설계 사양
- [PHASE3_GUIDE.md](../../PHASE3_GUIDE.md): Phase 3 기능 가이드
- [TCA Philosophy](./TCA_PHILOSOPHY.md): 왜 결정론적 테스트인가?

---

**마이그레이션 도구 버전:** 2.0.0  
**최종 수정:** 2026-02-04  
**지원:** GitHub Issues

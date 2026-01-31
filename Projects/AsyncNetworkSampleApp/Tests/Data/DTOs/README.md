# DTO Tests - Builder + Mock 패턴 가이드

## 개요

AsyncNetwork v1.3.1부터 `@ResponseTestable` 매크로가 극도로 간소화되어 Builder 패턴이 mock 기반으로 동작합니다.

## 핵심 개념

### Builder는 Mock 기반
```swift
// Builder는 내부적으로 mock()을 호출하여 초기화됩니다
let data = UserDTO.builder().build()
// ≈ UserDTO.mock()와 동일 (모든 필드가 랜덤)
```

## 7가지 테스트 패턴

### Pattern 1: 완전 랜덤 (테스트 독립성)
**용도**: 엣지 케이스 발견, 테스트 독립성 보장

```swift
@Test("Pattern 1: 완전 랜덤 - mock()만 사용")
func pattern1_FullyRandom() {
    let random = CourseDTO.mock()
    
    // 매번 다른 값
    #expect(!random.id.isEmpty)
    random.assertValid()
}
```

### Pattern 2: 완전 고정 (특정 시나리오)
**용도**: 재현 가능한 시나리오, 경계값 테스트

```swift
@Test("Pattern 2: 완전 고정 - builder로 모든 필드 지정")
func pattern2_FullyFixed() {
    let fixed = CourseDTO.builder()
        .with(id: "course-001")
        .with(title: "Swift Fundamentals")
        .with(description: "Learn Swift basics")
        .build()
    
    // 항상 동일한 값
    #expect(fixed.id == "course-001")
}
```

### Pattern 3: 하이브리드 ⭐ (권장)
**용도**: 특정 필드만 제어, 나머지는 자동 생성

```swift
@Test("Pattern 3: 하이브리드 - 일부만 고정, 나머지는 랜덤")
func pattern3_Hybrid() {
    // id만 고정, title/description은 랜덤
    let hybrid = CourseDTO.builder()
        .with(id: "test-course-999")
        .build()
    
    #expect(hybrid.id == "test-course-999") // 고정
    #expect(!hybrid.title.isEmpty) // 랜덤
}
```

### Pattern 4: 배열 생성
**용도**: 대량 데이터 테스트, 페이지네이션 테스트

```swift
@Test("Pattern 4: 배열 생성 - mockArray()로 여러 개 생성")
func pattern4_Array() {
    let courses = CourseDTO.mockArray(count: 10)
    
    #expect(courses.count == 10)
    
    // 모든 ID가 유니크한지 확인
    let ids = Set(courses.map { $0.id })
    #expect(ids.count == 10)
}
```

### Pattern 5: Builder + 커스텀 배열
**용도**: 특정 조건의 데이터 세트 생성

```swift
@Test("Pattern 5: Builder + 커스텀 배열 - 일부만 고정")
func pattern5_CustomArray() {
    let beginnerCourses = (1...5).map { index in
        CourseDTO.builder()
            .with(id: "beginner-\(index)")
            .with(title: "Beginner Course \(index)")
            // description은 랜덤
            .build()
    }
    
    #expect(beginnerCourses.count == 5)
}
```

### Pattern 6: 실전 시나리오
**용도**: 비즈니스 로직 테스트

```swift
@Test("Pattern 6: 실전 시나리오 - 특정 조건 테스트")
func pattern6_RealWorldScenario() {
    // Swift 과정 3개, 다른 과정 2개 생성
    let swiftCourses = (1...3).map { index in
        CourseDTO.builder()
            .with(id: "swift-\(index)")
            .build()
    }
    
    let otherCourses = [
        CourseDTO.builder().with(id: "python-101").build(),
        CourseDTO.builder().with(id: "kotlin-basics").build()
    ]
    
    let allCourses = swiftCourses + otherCourses

    // "swift-"로 시작하는 Course 필터링
    let filteredSwiftCourses = allCourses.filter { $0.id.hasPrefix("swift-") }
    
    #expect(filteredSwiftCourses.count == 3)
}
```

### Pattern 7: 중첩 DTO
**용도**: 복잡한 응답 구조 테스트

```swift
@Test("Pattern 7: 중첩 DTO - Builder + Mock 조합")
func pattern7_NestedDTO() {
    let customCourse1 = CourseDTO.builder()
        .with(id: "custom-1")
        .with(title: "Custom Course 1")
        .build()
    
    let customCourse2 = CourseDTO.builder()
        .with(id: "custom-2")
        .build() // title, description은 랜덤
    
    let response = GetCoursesResponseDTO.builder()
        .with(items: [customCourse1, customCourse2])
        .with(nextToken: "custom-token")
        .build()

    #expect(response.items.count == 2)
    #expect(response.items[0].id == "custom-1")
}
```

## 실전 예시

### 예시 1: 특정 postId를 가진 댓글들 생성
```swift
@Test("실전 예시: 특정 postId를 가진 댓글들 생성")
func realWorldExample1() {
    let postId = 100
    let comments = (1...5).map { index in
        CommentDTO.builder()
            .with(id: index)
            .with(postId: postId)
            // name, email, body는 랜덤
            .build()
    }
    
    // 모든 댓글이 같은 postId를 가짐
    for comment in comments {
        #expect(comment.postId == postId)
    }
}
```

### 예시 2: 관리자 vs 일반 사용자 데이터
```swift
@Test("실전 예시: 관리자 댓글 vs 일반 댓글")
func realWorldExample2() {
    // 관리자 댓글 (고정 email)
    let adminComment = CommentDTO.builder()
        .with(email: "admin@example.com")
        .with(name: "Administrator")
        .build()

    // 일반 사용자 댓글 (완전 랜덤)
    let userComment = CommentDTO.mock()

    #expect(adminComment.email == "admin@example.com")
    #expect(!userComment.email.isEmpty)
}
```

## 언제 어떤 패턴을 사용할까?

| 상황 | 권장 패턴 |
|------|----------|
| 테스트 독립성이 중요할 때 | Pattern 1 (완전 랜덤) |
| 재현 가능한 버그 테스트 | Pattern 2 (완전 고정) |
| 특정 필드만 제어하고 싶을 때 | Pattern 3 (하이브리드) ⭐ |
| 대량 데이터 테스트 | Pattern 4 (배열 생성) |
| 복잡한 조건의 데이터 세트 | Pattern 5 (커스텀 배열) |
| 비즈니스 로직 검증 | Pattern 6 (실전 시나리오) |
| 중첩된 응답 구조 | Pattern 7 (중첩 DTO) |

## 마이그레이션 가이드

### Before (v1.2.0) - fixture 사용
```swift
let data = UserDTO.fixture()
#expect(data.id == 1) // 항상 같은 값
```

### After (v1.3.1) - builder 사용
```swift
// 완전 고정 (fixture와 동일)
let data = UserDTO.builder()
    .with(id: 1)
    .with(name: "Test")
    .build()

// 하이브리드 (권장)
let data = UserDTO.builder()
    .with(id: 1)
    .build() // name은 랜덤
```

## 장점

1. **유연성**: 랜덤 + 고정 혼합 가능
2. **간결함**: 파라미터 없이 `@ResponseTestable`만 작성
3. **테스트 독립성**: mock 기반으로 매번 다른 값
4. **안정성**: fixtureJSON 검증 오류 제거
5. **성능**: 복잡한 JSON 파싱 제거

## 참고

- AsyncNetwork 버전: v1.3.1+
- 매크로 구현: `ResponseTestableMacroImpl.swift`
- 관련 문서: `/docs/ResponseTestable-Simplified.md`

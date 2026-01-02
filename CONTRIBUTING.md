# 기여 가이드 (Contributing Guide)

AsyncNetwork 프로젝트에 관심을 가져주셔서 감사합니다! 🎉

이 가이드는 프로젝트에 기여하는 방법을 안내합니다.

---

## 📋 목차

- [행동 강령](#-행동-강령)
- [기여 방법](#-기여-방법)
- [개발 환경 설정](#-개발-환경-설정)
- [코딩 규칙](#-코딩-규칙)
- [커밋 컨벤션](#-커밋-컨벤션)
- [Pull Request 프로세스](#-pull-request-프로세스)
- [테스트 작성](#-테스트-작성)
- [문서화](#-문서화)

---

## 📜 행동 강령

AsyncNetwork은 모든 기여자들이 존중받고 환영받는 환경을 만들기 위해 노력합니다.

### 우리의 약속

- 🤝 서로 존중하고 배려합니다
- 💬 건설적인 피드백을 제공합니다
- 🌍 다양성을 존중합니다
- 🎯 프로젝트의 목표에 집중합니다

---

## 🚀 기여 방법

### 1. 이슈 확인

먼저 [Issues](https://github.com/Jimmy-Jung/AsyncNetwork/issues)에서 작업하고 싶은 문제를 찾거나 새로운 이슈를 생성합니다.

#### 좋은 첫 이슈

처음 기여하시나요? `good first issue` 라벨이 붙은 이슈부터 시작해보세요!

#### 이슈 라벨

- `bug`: 버그 수정
- `enhancement`: 새로운 기능 추가
- `documentation`: 문서 개선
- `good first issue`: 초보자에게 적합한 이슈
- `help wanted`: 도움이 필요한 이슈

### 2. Fork 및 브랜치 생성

```bash
# 1. 저장소 Fork
# GitHub에서 "Fork" 버튼 클릭

# 2. 로컬에 Clone
git clone https://github.com/YOUR_USERNAME/AsyncNetwork.git
cd AsyncNetwork

# 3. 원본 저장소를 upstream으로 추가
git remote add upstream https://github.com/Jimmy-Jung/AsyncNetwork.git

# 4. 브랜치 생성
git checkout -b feature/amazing-feature
```

### 3. 개발

코드를 작성하고 테스트를 추가합니다.

### 4. 커밋 및 푸시

```bash
# 변경사항 커밋
git add .
git commit -m 'feat: add amazing feature'

# 푸시
git push origin feature/amazing-feature
```

### 5. Pull Request 생성

GitHub에서 Pull Request를 생성합니다.

---

## 🛠️ 개발 환경 설정

### 요구사항

- Xcode 15.0+
- Swift 6.0+
- macOS 14.0+

### 프로젝트 설정

```bash
# 1. 저장소 클론
git clone https://github.com/Jimmy-Jung/AsyncNetwork.git
cd AsyncNetwork

# 2. Swift Package 열기
open Package.swift

# 또는 Xcode에서 직접 열기
open AsyncNetwork.xcodeproj
```

### 의존성 설치

프로젝트는 Swift Package Manager를 사용하며, Xcode에서 자동으로 의존성을 다운로드합니다.

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0")
]
```

---

## 📝 코딩 규칙

### Swift Style Guide

AsyncNetwork은 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)를 따릅니다.

#### 네이밍

```swift
// ✅ Good
func fetchUserProfile(for userId: Int) async throws -> UserProfile

// ❌ Bad
func getUserData(_ id: Int) async throws -> UserProfile
```

#### 접근 제어

```swift
// 가능한 한 제한적으로 유지
public protocol APIRequest { }
internal struct DefaultConfiguration { }
private func validateResponse() { }
```

#### 타입 안전성

```swift
// ✅ Good - 타입 안전
@QueryParameter var userId: Int

// ❌ Bad - 타입 불안전
@QueryParameter var userId: String
```

### 코드 구조

```swift
// MARK: - Protocol Definition
public protocol MyProtocol {
    // ...
}

// MARK: - Implementation
public struct MyStruct: MyProtocol {
    // MARK: - Properties
    private let property: String
    
    // MARK: - Initializers
    public init(property: String) {
        self.property = property
    }
    
    // MARK: - Public Methods
    public func myMethod() {
        // ...
    }
    
    // MARK: - Private Methods
    private func helperMethod() {
        // ...
    }
}

// MARK: - Extensions
extension MyStruct {
    // ...
}
```

### 주석

```swift
/// API 요청을 나타내는 프로토콜
///
/// **사용 예시:**
/// ```swift
/// @APIRequest(
///     response: [Post].self,
///     title: "Get all posts",
///     baseURL: "https://api.example.com",
///     path: "/posts",
///     method: "get"
/// )
/// struct GetPostsRequest {}
/// ```
public protocol APIRequest: Sendable {
    /// 응답 타입 정의
    /// - Note: 빈 응답의 경우 `EmptyResponse`를 사용하세요
    associatedtype Response: Decodable
}
```

---

## 💬 커밋 컨벤션

AsyncNetwork은 [Conventional Commits](https://www.conventionalcommits.org/) 규칙을 따릅니다.

### 커밋 메시지 형식

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

- `feat`: 새로운 기능 추가
- `fix`: 버그 수정
- `docs`: 문서 변경
- `style`: 코드 포맷팅 (기능 변경 없음)
- `refactor`: 코드 리팩토링
- `test`: 테스트 추가/수정
- `chore`: 빌드 프로세스, 도구 설정 등

### Scope (선택사항)

- `core`: AsyncNetworkCore
- `macros`: AsyncNetworkMacros
- `interceptor`: RequestInterceptor
- `retry`: RetryPolicy
- `test`: 테스트

### 예시

```bash
# 기능 추가
git commit -m 'feat(interceptor): add AuthInterceptor'

# 버그 수정
git commit -m 'fix(core): resolve memory leak in HTTPClient'

# 문서 업데이트
git commit -m 'docs: update README installation guide'

# 리팩토링
git commit -m 'refactor(retry): simplify RetryPolicy logic'

# 테스트 추가
git commit -m 'test(macros): add APIRequest macro tests'
```

---

## 🔄 Pull Request 프로세스

### PR 체크리스트

PR을 생성하기 전에 다음을 확인하세요:

- [ ] 코드가 빌드되고 모든 테스트가 통과합니다
- [ ] 새로운 기능에 대한 테스트를 추가했습니다
- [ ] 문서를 업데이트했습니다 (필요한 경우)
- [ ] 커밋 메시지가 컨벤션을 따릅니다
- [ ] PR 설명이 명확합니다

### PR 템플릿

```markdown
## 변경사항

이 PR에서 변경된 내용을 설명해주세요.

## 관련 이슈

Closes #123

## 테스트

어떤 테스트를 추가했나요?

## 체크리스트

- [ ] 빌드 성공
- [ ] 테스트 통과
- [ ] 문서 업데이트
- [ ] 커밋 메시지 컨벤션 준수
```

### 리뷰 프로세스

1. PR이 생성되면 자동으로 CI가 실행됩니다
2. 메인테이너가 코드를 리뷰합니다
3. 요청된 변경사항을 반영합니다
4. 승인 후 메인테이너가 머지합니다

---

## 🧪 테스트 작성

### 테스트 구조

```swift
import Testing
@testable import AsyncNetwork

@Test("API 요청 성공 케이스")
func testAPIRequestSuccess() async throws {
    // Given
    let mockResponse = """
    {"id": 1, "name": "Test"}
    """
    
    MockURLProtocol.requestHandler = { request in
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, mockResponse.data(using: .utf8)!)
    }
    
    // When
    let result = try await service.request(MyAPI.getUser)
    
    // Then
    #expect(result.id == 1)
    #expect(result.name == "Test")
}
```

### 테스트 실행

```bash
# 모든 테스트 실행
swift test

# 특정 타겟 테스트
swift test --filter AsyncNetworkTests

# 코드 커버리지
swift test --enable-code-coverage
```

---

## 📚 문서화

### DocC 주석

```swift
/// API 요청을 처리하는 네트워크 서비스
///
/// `NetworkService`는 AsyncNetwork의 핵심 컴포넌트로,
/// API 요청을 실행하고 응답을 처리합니다.
///
/// ## Topics
///
/// ### 요청 실행
/// - ``request(_:)``
/// - ``requestRaw(_:)``
///
/// ### 설정
/// - ``configuration``
/// - ``retryPolicy``
///
/// ## 사용 예시
///
/// ```swift
/// let service = NetworkService()
/// let posts: [Post] = try await service.request(GetPostsRequest())
/// ```
public final class NetworkService {
    // ...
}
```

### README 업데이트

새로운 기능을 추가하면 README.md도 업데이트해주세요.

---

## ❓ 질문이나 도움이 필요하신가요?

- 💬 [Discussions](https://github.com/Jimmy-Jung/AsyncNetwork/discussions)에서 질문하세요
- 🐛 버그를 발견하셨나요? [Issues](https://github.com/Jimmy-Jung/AsyncNetwork/issues)에 리포트해주세요
- 📧 이메일: joony300@gmail.com

---

## 🙏 감사합니다!

AsyncNetwork에 기여해주셔서 감사합니다! 여러분의 기여는 프로젝트를 더 좋게 만듭니다. 🚀

---

<div align="center">

**Made with ❤️ by the AsyncNetwork community**

</div>


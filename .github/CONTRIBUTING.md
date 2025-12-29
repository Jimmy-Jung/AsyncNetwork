# Contributing to NetworkKit

NetworkKit에 기여해주셔서 감사합니다! 이 문서는 프로젝트에 기여하는 방법을 안내합니다.

## 목차

- [행동 강령](#행동-강령)
- [시작하기](#시작하기)
- [개발 워크플로우](#개발-워크플로우)
- [코딩 규칙](#코딩-규칙)
- [커밋 컨벤션](#커밋-컨벤션)
- [Pull Request 프로세스](#pull-request-프로세스)
- [이슈 리포팅](#이슈-리포팅)

## 행동 강령

이 프로젝트는 [Contributor Covenant](https://www.contributor-covenant.org/) 행동 강령을 따릅니다. 프로젝트에 참여함으로써 이 규칙을 준수하는 데 동의하는 것입니다.

## 시작하기

### 필수 요구사항

- Xcode 16.0 이상
- Swift 6.0 이상
- macOS 14.0 이상
- Tuist 4.x (Example 프로젝트 빌드 시)

### 저장소 클론

```bash
git clone https://github.com/Jimmy-Jung/NetworkKit.git
cd NetworkKit
```

### 프로젝트 구조

```
NetworkKit/
├── Package.swift                    # SPM 패키지 정의
├── Projects/
│   ├── NetworkKit/                  # Core 라이브러리
│   │   ├── Sources/                 # 소스 코드
│   │   └── Tests/                   # 단위 테스트
│   └── NetworkKitExample/           # Example 앱 (Tuist)
└── .github/                         # GitHub 설정
```

### 빌드 및 테스트

```bash
# NetworkKit 패키지 빌드 및 테스트
swift build
swift test

# Example 프로젝트 실행
cd Projects/NetworkKitExample
tuist install
tuist generate
open NetworkKitExample.xcworkspace
```

## 개발 워크플로우

### 1. 브랜치 생성

```bash
# 기능 추가
git checkout -b feature/your-feature-name

# 버그 수정
git checkout -b fix/bug-description

# 문서 업데이트
git checkout -b docs/what-you-are-documenting
```

### 2. 변경 사항 작성

- 코드를 작성하고 테스트를 추가합니다
- SwiftLint 규칙을 준수합니다
- 모든 테스트가 통과하는지 확인합니다

### 3. 커밋

```bash
git add .
git commit -m "feat: add new feature"
```

커밋 메시지는 [Conventional Commits](https://www.conventionalcommits.org/) 형식을 따릅니다.

### 4. Push 및 Pull Request

```bash
git push origin feature/your-feature-name
```

GitHub에서 Pull Request를 생성합니다.

## 코딩 규칙

### Swift API Design Guidelines

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)를 따릅니다
- 명확하고 읽기 쉬운 코드를 작성합니다
- 적절한 주석과 문서화를 추가합니다

### 코드 스타일

- SwiftLint 규칙을 준수합니다
- 들여쓰기는 4칸 공백을 사용합니다
- 최대 줄 길이는 120자입니다 (권장)

### 테스트

- 모든 새로운 기능에는 테스트를 추가합니다
- Swift Testing 프레임워크를 사용합니다
- 테스트는 명확하고 이해하기 쉬워야 합니다

```swift
import Testing
@testable import NetworkKit

@Suite("HTTPClient Tests")
struct HTTPClientTests {
    @Test("should perform GET request successfully")
    func testGetRequest() async throws {
        // Given
        let client = HTTPClient()
        
        // When
        let response = try await client.request(...)
        
        // Then
        #expect(response.statusCode == 200)
    }
}
```

### 문서화

- 공개 API에는 문서 주석을 추가합니다
- DocC 형식을 따릅니다

```swift
/// HTTP 요청을 수행하는 클라이언트
///
/// HTTPClient는 URLSession을 기반으로 HTTP 요청을 수행하고
/// 응답을 처리하는 기능을 제공합니다.
///
/// ## Usage
///
/// ```swift
/// let client = HTTPClient(logger: ConsoleNetworkLogger())
/// let response = try await client.request(MyAPI.getUsers)
/// ```
public final class HTTPClient { ... }
```

## 커밋 컨벤션

Conventional Commits 형식을 사용합니다:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

- `feat`: 새로운 기능
- `fix`: 버그 수정
- `docs`: 문서 변경
- `style`: 코드 스타일 변경 (포매팅, 세미콜론 등)
- `refactor`: 리팩토링
- `test`: 테스트 추가/수정
- `chore`: 빌드 프로세스, 도구 설정 등

### Scope (선택 사항)

- `core`: Core 타입 (APIRequest, HTTPMethod 등)
- `infrastructure`: Infrastructure 계층
- `application`: Application 계층
- `orchestration`: Orchestration 계층
- `example`: Example 프로젝트

### 예시

```bash
feat(core): add multipart form data support
fix(infrastructure): fix response decoder issue
docs: update README with installation guide
test(orchestration): add network service tests
```

## Pull Request 프로세스

### PR 생성 전 체크리스트

- [ ] 코드가 빌드되고 모든 테스트가 통과합니다
- [ ] SwiftLint 경고가 없습니다
- [ ] 새로운 기능에 대한 테스트를 추가했습니다
- [ ] 문서를 업데이트했습니다 (필요한 경우)
- [ ] Breaking Change가 있다면 명시했습니다

### PR 설명

- 변경 사항을 명확하게 설명합니다
- 관련 이슈를 링크합니다
- 스크린샷을 추가합니다 (UI 변경 시)

### 리뷰 프로세스

1. PR을 생성하면 자동으로 CI가 실행됩니다
2. 리뷰어가 코드를 검토합니다
3. 피드백을 반영합니다
4. 승인되면 main 브랜치에 병합됩니다

## 이슈 리포팅

### 버그 리포트

버그를 발견하셨나요? [Bug Report](https://github.com/Jimmy-Jung/NetworkKit/issues/new?template=bug_report.yml)를 작성해주세요.

### 기능 제안

새로운 기능을 제안하고 싶으신가요? [Feature Request](https://github.com/Jimmy-Jung/NetworkKit/issues/new?template=feature_request.yml)를 작성해주세요.

## 질문이 있으신가요?

- [Discussions](https://github.com/Jimmy-Jung/NetworkKit/discussions)에서 질문하세요
- [Issues](https://github.com/Jimmy-Jung/NetworkKit/issues)를 확인하세요

## 라이선스

기여하신 코드는 [MIT License](../LICENSE)에 따라 배포됩니다.

---

다시 한번 NetworkKit에 기여해주셔서 감사합니다! 🎉


# AsyncNetwork Tuist Workspace 구조

이 문서는 AsyncNetwork 프로젝트의 Tuist Workspace 구조를 설명합니다.

## 🏗 프로젝트 구조

```
AsyncNetwork/
├── Package.swift              # SPM 패키지 정의 (AsyncNetwork, AsyncNetworkMacros)
├── Workspace.swift            # Tuist Workspace 정의
├── Tuist.swift                # Tuist 전역 설정
├── Tuist/
│   └── Package.swift          # 외부 의존성 (AsyncViewModel, TraceKit, SwiftSyntax)
├── Projects/
│   ├── AsyncNetwork/          # 메인 라이브러리 (SPM으로 관리)
│   │   ├── Sources/
│   │   └── Tests/
│   ├── AsyncNetworkMacros/    # 매크로 (SPM으로 관리)
│   │   ├── Sources/
│   │   └── Tests/
│   └── AsyncNetworkExample/   # 데모 앱 (Tuist로 관리)
│       ├── Project.swift
│       └── AsyncNetworkExample/
│           ├── Sources/       # 12가지 예시 포함
│           └── Resources/
└── AsyncNetwork.xcworkspace/  # 생성된 Workspace (gitignore)
```

## 📦 의존성 구조

### AsyncNetwork (SPM)
- Swift Syntax 600+ (매크로 지원)
- 순수 Swift, iOS 13.0+

### AsyncNetworkExample (Tuist)
- AsyncNetwork (로컬, SPM)
- AsyncNetworkMacros (로컬, SPM)
- AsyncViewModel (외부, GitHub)
- TraceKit (외부, GitHub)

## 🎯 Tuist 명령어

### 초기 설정
```bash
tuist install   # 외부 의존성 설치
tuist generate  # Workspace 생성
```

### 개발 워크플로우
```bash
# 1. 코드 수정 (Swift 파일)
# 2. Xcode에서 빌드 및 실행

# 의존성이 변경된 경우만:
tuist install
tuist generate
```

### 정리
```bash
tuist clean     # 캐시 정리
```

## 🔄 SPM vs Tuist 역할 분담

### SPM (Package.swift)
- **AsyncNetwork 라이브러리**: 핵심 네트워킹 로직
- **AsyncNetworkMacros**: 컴파일 타임 매크로
- **배포**: GitHub Packages, CocoaPods 등

### Tuist (Workspace.swift + Project.swift)
- **AsyncNetworkExample**: 데모 앱
- **통합**: 로컬 패키지 + 외부 의존성
- **개발 환경**: 전체 워크스페이스 관리

## 📝 Tuist/Package.swift 역할

외부 의존성을 정의하고 Tuist가 이를 관리합니다:

```swift
let package = Package(
    name: "AsyncNetworkDependencies",
    dependencies: [
        .package(path: ".."),  // 로컬 AsyncNetwork
        .package(url: "https://github.com/Jimmy-Jung/AsyncViewModel", from: "1.2.0"),
        .package(url: "https://github.com/Jimmy-Jung/TraceKit.git", from: "1.1.2"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0"),
    ]
)
```

## ⚙️ Tuist.swift 역할

전역 설정:

```swift
let config = Config(
    compatibleXcodeVersions: .all,
    swiftVersion: "6.0",
    generationOptions: .options(
        disableSandbox: true
    )
)
```

## 🎨 Workspace.swift 역할

포함할 프로젝트를 정의:

```swift
let workspace = Workspace(
    name: "AsyncNetwork",
    projects: [
        "Projects/AsyncNetworkExample"  // Example만 Tuist로 관리
    ]
)
```

## ✅ 장점

1. **분리된 관심사**
   - SPM: 라이브러리 배포
   - Tuist: 데모 앱 개발

2. **최소한의 Tuist 사용**
   - Example 앱만 Tuist 관리
   - 라이브러리는 SPM 유지

3. **쉬운 온보딩**
   - `tuist install && tuist generate` 한 줄로 시작

4. **일관된 개발 환경**
   - 모든 개발자가 동일한 프로젝트 구조 사용

## 🚀 신규 개발자 온보딩

```bash
# 1. 저장소 클론
git clone https://github.com/your-repo/AsyncNetwork.git
cd AsyncNetwork

# 2. Tuist 설정 (한 번만)
tuist install
tuist generate

# 3. Xcode 열기
open AsyncNetwork.xcworkspace

# 4. AsyncNetworkExample 스킴 선택 후 실행!
```

## 📚 참고

- [Tuist 공식 문서](https://docs.tuist.io)
- [Swift Package Manager 가이드](https://swift.org/package-manager)


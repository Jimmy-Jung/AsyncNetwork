# AsyncNetwork Scripts

AsyncNetwork의 자동 코드 생성 스크립트 모음입니다.

## 📁 Scripts 구조

```
Scripts/
├── CreateDocKitExample.swift          # 샘플 앱 자동 생성
├── GenerateTypeRegistration.swift    # @DocumentedType 등록 코드 생성
├── GenerateEndpoints.swift            # @APIRequest 엔드포인트 생성
└── README.md                          # 이 문서
```

---

## 🚀 CreateDocKitExample.swift

API 문서 샘플 앱을 자동으로 생성하는 스크립트입니다.

### 실행 위치

#### 케이스 1: 사용자가 자신의 프로젝트에서 사용 (일반적인 경우)

```bash
# 1. 사용자 프로젝트 루트로 이동
cd /path/to/YourProject

# 2. Package.swift에 AsyncNetwork 의존성 추가
dependencies: [
    .package(url: "https://github.com/Jimmy-Jung/AsyncNetwork.git", from: "1.0.0")
]

# 3. AsyncNetwork 다운로드
swift package resolve

# 4. 스크립트 실행
swift .build/checkouts/AsyncNetwork/Scripts/CreateDocKitExample.swift
```

**프로젝트 구조**:
```
YourProject/                    ← 현재 위치 (여기서 swift package resolve 실행)
├── Package.swift
├── Sources/
│   ├── Domain/                 ← @DocumentedType 경로
│   └── Network/                ← @APIRequest 경로
└── .build/
    └── checkouts/
        └── AsyncNetwork/       ← AsyncNetwork가 다운로드됨
            └── Scripts/
                └── CreateDocKitExample.swift
```

#### 케이스 2: AsyncNetwork 저장소를 직접 클론한 경우

```bash
# 1. AsyncNetwork 저장소로 이동
cd /path/to/AsyncNetwork

# 2. 스크립트 실행
swift Scripts/CreateDocKitExample.swift
```

**프로젝트 구조**:
```
AsyncNetwork/                   ← 현재 위치
├── Package.swift
├── Scripts/
│   └── CreateDocKitExample.swift
└── Projects/
    ├── Domain/                 ← @DocumentedType 경로 (예시)
    └── Data/                   ← @APIRequest 경로 (예시)
```

### 기능

- ✅ 대화형 입력 모드
- ✅ 경로 자동 정규화 (절대/상대/홈 경로)
- ✅ Tuist 모듈 자동 감지
- ✅ Placeholder 파일 자동 생성
- ✅ 빌드 스크립트 자동 설정

### 사용법

#### 1️⃣ 대화형 모드 (권장)

**사용자 프로젝트에서**:
```bash
cd /path/to/YourProject
swift .build/checkouts/AsyncNetwork/Scripts/CreateDocKitExample.swift
```

**AsyncNetwork 저장소에서**:
```bash
cd /path/to/AsyncNetwork
swift Scripts/CreateDocKitExample.swift
```

**입력 예시** (사용자 프로젝트 기준):
```
📱 앱 이름: MyAPIDocumentation

📁 @DocumentedType 경로: Sources/Domain
   💡 여러 개는 ','로 구분 (예: Sources/Domain,Sources/Models)
   💡 절대 경로, 상대 경로, ~ 모두 사용 가능
   
📡 @APIRequest 경로: Sources/Network
   💡 위와 같으면 Enter
   💡 다르면 입력 (예: Sources/API,Sources/Data)

📂 출력 경로: DocKitExample
   💡 샘플 앱이 생성될 위치 (현재 디렉토리 기준)

🔖 Bundle ID 접두사: com.mycompany (기본값: com.asyncnetwork)

🛠  스크립트 경로: ../../Scripts (기본값)
   💡 생성될 샘플앱에서 AsyncNetwork Scripts까지의 상대 경로
   💡 사용자 프로젝트: .build/checkouts/AsyncNetwork/Scripts
   💡 AsyncNetwork 클론: ../../Scripts

🎯 생성하시겠습니까? y
```

#### 2️⃣ 명령줄 모드

```bash
swift Scripts/CreateDocKitExample.swift \
    --name MyAPIDocumentation \
    --sources Sources/Domain \
    --sources Sources/Network \
    --output DocKitExample \
    --bundle-id com.mycompany \
    --scripts ../../Scripts
```

### 경로 지정

스크립트는 다양한 경로 형식을 자동으로 처리합니다:

```bash
# 절대 경로
/Users/username/Project/Sources/Domain

# 상대 경로
Sources/Domain
../MyProject/Sources/Network

# 홈 경로
~/Projects/MyApp/Sources/Domain

# 따옴표 포함 (자동 제거됨)
"Sources/Domain"
'Sources/Network'
```

### Tuist 모듈 자동 감지

스크립트는 경로에 `Project.swift`가 있으면 자동으로 Tuist 모듈로 인식합니다:

```bash
# 예시: Data, Domain이 Tuist 모듈인 경우
📁 @DocumentedType 경로: Projects/Domain
📡 @APIRequest 경로: Projects/Data

# 결과: Project.swift에 자동 추가
dependencies: [
    .project(target: "Domain", path: "../../Projects/Domain"),
    .project(target: "Data", path: "../../Projects/Data"),
]
```

일반 폴더인 경우 `sources`에 추가:
```swift
sources: [
    "MyApp/Sources/**",
    "../../Sources/Models/**",
]
```

### 생성되는 파일

**사용자 프로젝트 기준**:
```
YourProject/                    ← 현재 위치
├── Package.swift
├── Sources/
│   ├── Domain/                 ← 사용자의 @DocumentedType
│   └── Network/                ← 사용자의 @APIRequest
└── DocKitExample/              ← 생성된 샘플 앱
    ├── Project.swift (Tuist)
    └── MyAPIDocumentation/
        ├── Sources/
        │   ├── MyAPIDocumentationApp.swift
        │   ├── TypeRegistration+Generated.swift  # 빌드 시 자동 생성
        │   └── Endpoints+Generated.swift         # 빌드 시 자동 생성
        └── Resources/
```

**AsyncNetwork 저장소 기준**:
```
AsyncNetwork/                   ← 현재 위치
├── Scripts/
├── Projects/
│   ├── Domain/                 ← @DocumentedType
│   └── Data/                   ← @APIRequest
└── DocKitExample/              ← 생성된 샘플 앱
    └── (위와 동일)
```

### 실행

```bash
cd DocKitExample
tuist generate
open MyAPIDocumentation.xcworkspace
# Cmd + R로 실행!
```

---

## 📝 GenerateTypeRegistration.swift

`@DocumentedType`이 적용된 타입을 스캔하여 자동 등록 코드를 생성합니다.

### 기능

- ✅ `@DocumentedType` 자동 스캔
- ✅ `registerAllTypesGenerated()` 메서드 생성
- ✅ 타임스탬프 및 타입 개수 자동 기록
- ✅ 제외 경로 지원 (.build, Derived 등)

### 사용법

```bash
swift Scripts/GenerateTypeRegistration.swift \
    --project <소스경로> \
    --output <출력파일> \
    --module <모듈명> \
    --target <타겟명> \
    [--verbose]
```

### 예시

```bash
swift Scripts/GenerateTypeRegistration.swift \
    --project Sources/Domain \
    --project Sources/Models \
    --output Generated/TypeRegistration+Generated.swift \
    --module MyApp \
    --target MyAppApp \
    --verbose
```

### 출력 예시

```swift
//
//  TypeRegistration+Generated.swift
//  MyApp
//
//  Auto-generated by GenerateTypeRegistration.swift
//  Created on 2026-01-03T12:46:12Z
//
//  DO NOT EDIT MANUALLY
//

import AsyncNetworkCore

extension MyAppApp {
    /// 모든 @DocumentedType 타입을 자동으로 등록합니다
    ///
    /// - Note: 생성된 타입 수: 37개
    func registerAllTypesGenerated() {
        _ = User.typeStructure
        _ = Post.typeStructure
        _ = Comment.typeStructure
        // ... (37개 타입)
    }
}
```

### Xcode Build Phase에서 사용

`Project.swift`에 추가:

```swift
scripts: [
    .pre(
        script: """
        set -e
        
        SCRIPTS_DIR="${SRCROOT}/../../Scripts"
        OUTPUT_DIR="${SRCROOT}/MyApp/Sources"
        
        xcrun --sdk macosx swift "$SCRIPTS_DIR/GenerateTypeRegistration.swift" \\
            --project Sources/Domain \\
            --project Sources/Models \\
            --output "$OUTPUT_DIR/TypeRegistration+Generated.swift" \\
            --module "MyApp" \\
            --target "MyAppApp"
        """,
        name: "Generate Type Registration",
        basedOnDependencyAnalysis: false
    ),
]
```

---

## 📡 GenerateEndpoints.swift

`@APIRequest`가 적용된 Request를 스캔하여 엔드포인트 딕셔너리를 생성합니다.

### 기능

- ✅ `@APIRequest` 자동 스캔
- ✅ `tags` 기반 카테고리 자동 분류
- ✅ `endpointsGenerated` static 프로퍼티 생성
- ✅ 타임스탬프 및 통계 정보 자동 기록
- ✅ 제외 경로 지원

### 사용법

```bash
swift Scripts/GenerateEndpoints.swift \
    --project <소스경로> \
    --output <출력파일> \
    --module <모듈명> \
    --target <타겟명> \
    [--verbose]
```

### 예시

```bash
swift Scripts/GenerateEndpoints.swift \
    --project Sources/Network \
    --project Sources/API \
    --output Generated/Endpoints+Generated.swift \
    --module MyApp \
    --target MyAppApp \
    --verbose
```

### 출력 예시

```swift
//
//  Endpoints+Generated.swift
//  MyApp
//
//  Auto-generated by GenerateEndpoints.swift
//  Created on 2026-01-03T12:49:36Z
//
//  DO NOT EDIT MANUALLY
//

import AsyncNetworkDocKit

extension MyAppApp {
    /// 모든 API Endpoint 정보를 반환합니다
    ///
    /// - Note: 생성된 카테고리 수: 7개, 총 Endpoint 수: 16개
    static var endpointsGenerated: [String: [EndpointMetadata]] {
        [
            "Users": [
                GetUsersRequest.metadata,
                GetUserRequest.metadata,
                CreateUserRequest.metadata,
            ],
            "Posts": [
                GetPostsRequest.metadata,
                CreatePostRequest.metadata,
            ],
            // ... (7개 카테고리)
        ]
    }
}
```

### Xcode Build Phase에서 사용

`Project.swift`에 추가:

```swift
scripts: [
    .pre(
        script: """
        set -e
        
        SCRIPTS_DIR="${SRCROOT}/../../Scripts"
        OUTPUT_DIR="${SRCROOT}/MyApp/Sources"
        
        xcrun --sdk macosx swift "$SCRIPTS_DIR/GenerateEndpoints.swift" \\
            --project Sources/Network \\
            --output "$OUTPUT_DIR/Endpoints+Generated.swift" \\
            --module "MyApp" \\
            --target "MyAppApp"
        """,
        name: "Generate Endpoints",
        basedOnDependencyAnalysis: false
    ),
]
```

---

## 🔧 문제 해결

### 1. "스크립트를 찾을 수 없습니다"

```bash
# AsyncNetwork가 제대로 다운로드되었는지 확인
ls .build/checkouts/AsyncNetwork/Scripts/

# 없다면 resolve 다시 실행
swift package resolve
```

### 2. "@DocumentedType을 찾을 수 없음"

스크립트는 **디렉토리** 단위로 스캔합니다:

```bash
# ✅ 올바른 경로 (폴더)
--project Sources/Domain

# ❌ 잘못된 경로 (파일)
--project Sources/Domain/Models.swift
```

### 3. "tuist generate 후 생성 파일이 없음"

Placeholder 파일을 먼저 생성하세요:

```bash
# Placeholder 파일이 없으면 tuist generate가 인식하지 못함
# CreateDocKitExample.swift는 자동으로 생성하지만,
# 수동으로 만든 경우 직접 생성 필요

touch MyApp/Sources/TypeRegistration+Generated.swift
touch MyApp/Sources/Endpoints+Generated.swift

# 이제 tuist generate 실행
tuist generate
```

### 4. "SDK 관련 경고"

```
warning: using sysroot for 'iPhoneSimulator' but targeting 'MacOSX'
```

**해결**: `xcrun --sdk macosx swift` 사용 (이미 적용됨)

### 5. "경로에 공백이 포함되어 오류"

경로에 공백이 있으면 따옴표로 감싸세요:

```bash
# ✅ 올바른 방법
swift Scripts/CreateDocKitExample.swift \
    --sources "My Project/Sources/Domain"

# 또는 대화형 모드 사용 (자동 처리)
swift Scripts/CreateDocKitExample.swift
```

---

## 📚 통합 워크플로우

### 새 프로젝트 시작

```bash
# 1. AsyncNetwork 설치
swift package resolve

# 2. 샘플 앱 생성
swift .build/checkouts/AsyncNetwork/Scripts/CreateDocKitExample.swift

# 3. 입력
앱 이름: MyAPIDocumentation
@DocumentedType 경로: Sources/Domain
@APIRequest 경로: Sources/Network
출력 경로: DocKitExample

# 4. 실행
cd DocKitExample
tuist generate
open *.xcworkspace
```

### 기존 프로젝트에 추가

```bash
# 1. Scripts 복사
cp -r .build/checkouts/AsyncNetwork/Scripts ./Scripts

# 2. Project.swift에 빌드 스크립트 추가
# (위의 "Xcode Build Phase에서 사용" 참고)

# 3. tuist generate 후 빌드
tuist generate
# Xcode에서 빌드 시 자동 생성됨
```

---

## 🎯 모범 사례

### 1. 경로 조직화

```
YourProject/
├── Sources/
│   ├── Domain/          # @DocumentedType
│   │   └── Models/
│   ├── Network/         # @APIRequest
│   │   └── Requests/
│   └── YourApp/
└── Scripts/             # 생성 스크립트 복사
```

### 2. .gitignore 설정

```gitignore
# 자동 생성 파일 제외
**/TypeRegistration+Generated.swift
**/Endpoints+Generated.swift
```

### 3. CI/CD 통합

```yaml
# .github/workflows/build.yml
- name: Generate Code
  run: |
    swift Scripts/GenerateTypeRegistration.swift \
        --project Sources/Domain \
        --output Generated/TypeRegistration+Generated.swift \
        --module MyApp \
        --target MyAppApp
    
    swift Scripts/GenerateEndpoints.swift \
        --project Sources/Network \
        --output Generated/Endpoints+Generated.swift \
        --module MyApp \
        --target MyAppApp
```

---

## 📖 추가 리소스

- [AsyncNetwork README](../README.md) - 메인 문서
- [AsyncNetworkDocKitExample](../Projects/AsyncNetworkDocKitExample) - 완전한 예제
- [GitHub Issues](https://github.com/Jimmy-Jung/AsyncNetwork/issues) - 버그 리포트

---

**Made with ❤️ by AsyncNetwork Team**

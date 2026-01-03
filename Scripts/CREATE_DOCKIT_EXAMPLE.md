# 🚀 CreateDocKitExample.swift

DocKitExample 앱을 자동으로 생성하는 스크립트입니다.

## 🎯 실행 방법

### 1. 대화형 모드 (권장) 🆕

인자 없이 실행하면 대화형 모드로 실행됩니다:

```bash
swift Scripts/CreateDocKitExample.swift
```

#### ⚠️ 중요: 경로 입력 시 주의사항

- **따옴표 없이** 경로를 입력하세요
- 상대 경로와 절대 경로 모두 사용 가능
- `~`는 자동으로 홈 디렉토리로 확장됩니다

**올바른 입력 예시**:
```
✅ Projects/Sample
✅ /Users/jimmy/Documents/GitHub/AsyncNetwork/Projects/Sample
✅ ~/Documents/GitHub/AsyncNetwork/Projects/Sample
```

**잘못된 입력 예시**:
```
❌ 'Projects/Sample'           # 따옴표 포함
❌ '/Users/jimmy/.../Sample'   # 따옴표 포함
❌ "Projects/Sample"            # 큰따옴표 포함
```

#### 실행 예시

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🚀 CreateDocKitExample                                 ║
║      DocKitExample 앱 자동 생성 스크립트                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

🎯 대화형 모드로 DocKitExample 앱을 생성합니다
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📱 앱 이름을 입력하세요 (예: MyAPIDocKitExample): MyAPIDocKitExample
   ✓ 앱 이름: MyAPIDocKitExample

📁 @DocumentedType을 찾을 경로를 입력하세요
   모델/타입 정의가 있는 위치 (Models, Domain 등)
   💡 따옴표 없이 입력하세요!
💡 여러 개는 ','로 구분하세요 (예: path1,path2)
입력: Projects/Domain

📡 @APIRequest를 찾을 경로를 입력하세요
   API Request 정의가 있는 위치 (Data, Network 등)
   💡 따옴표 없이 입력하세요!
   💡 위에서 입력한 경로와 같으면 그냥 Enter를 누르세요
💡 여러 개는 ','로 구분하세요 (예: path1,path2)
입력: Projects/Data

   ✓ 모든 소스 경로:
     1. /Users/jimmy/Documents/GitHub/AsyncNetwork/Projects/Domain [일반 폴더]
     2. /Users/jimmy/Documents/GitHub/AsyncNetwork/Projects/Data [일반 폴더]

📂 출력 경로를 입력하세요 (예: Projects/MyAPIDocKitExample): Projects/MyAPIDocKitExample
   ✓ 출력 경로: Projects/MyAPIDocKitExample

🔖 Bundle ID 접두사를 입력하세요 (선택, 기본값: com.asyncnetwork)
입력: 
   ✓ Bundle ID: com.asyncnetwork.MyAPIDocKitExample

🛠  스크립트 경로를 입력하세요 (선택, 기본값: ../../Scripts)
입력: 
   ✓ 스크립트 경로: ../../Scripts

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 설정 확인
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 앱 이름:        MyAPIDocKitExample
🔖 Bundle ID:      com.asyncnetwork.MyAPIDocKitExample
📁 소스 경로:      /Users/jimmy/Documents/GitHub/AsyncNetwork/Projects/Domain
                   /Users/jimmy/Documents/GitHub/AsyncNetwork/Projects/Data
📂 출력 경로:      Projects/MyAPIDocKitExample
🛠  스크립트 경로:  ../../Scripts
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 프로젝트를 생성하시겠습니까? (y/n): y

📁 디렉토리 구조 생성 중...
✅ Directory structure created at: Projects/MyAPIDocKitExample
📝 파일 생성 중...
  ✅ Project.swift
  ✅ MyAPIDocKitExampleApp.swift
  📝 Placeholder 파일 생성 중...
    ✅ TypeRegistration+Generated.swift (placeholder)
    ✅ Endpoints+Generated.swift (placeholder)
  ✅ README.md
  ✅ .gitignore

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ✨ 프로젝트 생성 완료!                                   ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

📦 프로젝트: MyAPIDocKitExample
📍 위치: Projects/MyAPIDocKitExample

🎯 다음 단계:

  1️⃣  프로젝트로 이동
     $ cd Projects/MyAPIDocKitExample

  2️⃣  Tuist 프로젝트 생성
     $ tuist generate

  3️⃣  Xcode에서 열기
     $ open MyAPIDocKitExample.xcworkspace

  4️⃣  빌드 및 실행 (⌘ + R)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 팁: 빌드 시 자동으로 다음 파일들이 생성됩니다:
   • TypeRegistration+Generated.swift
   • Endpoints+Generated.swift
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2. 커맨드 라인 모드

```bash
swift Scripts/CreateDocKitExample.swift \
    --name <앱이름> \
    --sources <소스경로1> [--sources <소스경로2> ...] \
    --output <출력경로> \
    [--bundle-id <번들ID>] \
    [--scripts <스크립트경로>]
```

## 🎯 필수 인자

| 인자 | 약어 | 설명 | 예시 |
|------|------|------|------|
| `--name` | `-n` | 앱 이름 | MyAPIDocKitExample |
| `--sources` | `-s` | 소스 경로 (여러 개 가능) | Projects/MyAPI/Sources |
| `--output` | `-o` | 출력 경로 | Projects/MyAPIDocKitExample |

## 🔧 선택 인자

| 인자 | 약어 | 설명 | 기본값 |
|------|------|------|--------|
| `--bundle-id` | `-b` | Bundle ID 접두사 | com.asyncnetwork |
| `--scripts` | `-sp` | 스크립트 경로 | ../../Scripts |
| `--help` | `-h` | 도움말 표시 | - |

## 📝 예시

### 단일 소스 경로

```bash
swift Scripts/CreateDocKitExample.swift \
    --name MyAPIDocKitExample \
    --sources Projects/MyAPI/Sources \
    --output Projects/MyAPIDocKitExample
```

### 여러 소스 경로

```bash
swift Scripts/CreateDocKitExample.swift \
    --name MyAPIDocKitExample \
    --sources Projects/MyAPI/Sources \
    --sources Projects/MyModels/Sources \
    --output Projects/MyAPIDocKitExample \
    --bundle-id com.mycompany
```

### 커스텀 스크립트 경로

```bash
swift Scripts/CreateDocKitExample.swift \
    --name MyAPIDocKitExample \
    --sources Projects/MyAPI/Sources \
    --output Projects/MyAPIDocKitExample \
    --scripts Scripts
```

## 📦 생성되는 파일 구조

```
<output>/
├── Project.swift                    # Tuist 프로젝트 정의
│   └── (빌드 스크립트 포함)
├── <appName>/
│   ├── Sources/
│   │   └── <appName>App.swift      # 메인 앱 파일
│   └── Resources/                   # 리소스 폴더
├── README.md                        # 프로젝트 문서
└── .gitignore                       # Git 설정
```

## 🎯 생성 후 단계

1. 생성된 프로젝트로 이동:
```bash
cd <output>
```

2. Tuist 프로젝트 생성:
```bash
tuist generate
```

3. Xcode에서 열기:
```bash
open <appName>.xcworkspace
```

4. 빌드 및 실행 (Cmd + R)

## ✨ 자동으로 생성되는 기능

### 1. Project.swift
- Tuist 프로젝트 설정
- 빌드 스크립트 통합 (TypeRegistration + Endpoints 자동 생성)
- AsyncNetworkDocKit 의존성 설정

### 2. App 파일
- `registerAllTypesGenerated()` 호출
- `endpointsGenerated` 사용
- `DocKitFactory.createDocApp` 설정

### 3. README.md
- 프로젝트 설명
- 실행 방법
- 코드 생성 방법

### 4. .gitignore
- Xcode 파일 제외
- 자동 생성 파일 제외

## 🔄 빌드 시 자동 생성

생성된 프로젝트는 빌드 시 다음 파일들을 자동으로 생성합니다:

1. **TypeRegistration+Generated.swift**
   - 모든 `@DocumentedType` 타입을 스캔
   - `registerAllTypesGenerated()` 메서드 생성

2. **Endpoints+Generated.swift**
   - 모든 `@APIRequest` 타입을 스캔
   - `endpointsGenerated` 프로퍼티 생성
   - 카테고리별 자동 분류 (tags 기반)

## 📊 실행 결과 예시

```
🚀 CreateDocKitExample - DocKitExample 앱 자동 생성 스크립트

📁 Creating directory structure...
✅ Directory structure created at: Projects/MyAPIDocKitExample

📝 Generating files...
  ✅ Project.swift
  ✅ MyAPIDocKitExampleApp.swift
  ✅ README.md
  ✅ .gitignore

✨ MyAPIDocKitExample 프로젝트가 성공적으로 생성되었습니다!

📍 프로젝트 위치: Projects/MyAPIDocKitExample

🎯 다음 단계:
  1. cd Projects/MyAPIDocKitExample
  2. tuist generate
  3. open MyAPIDocKitExample.xcworkspace
```

## 🎨 생성되는 App 코드 예시

```swift
@main
@available(iOS 17.0, *)
struct MyAPIDocKitExampleApp: App {
    let networkService = NetworkService()

    init() {
        // 모든 @DocumentedType 타입을 자동으로 등록
        registerAllTypesGenerated()
    }

    var body: some Scene {
        DocKitFactory.createDocApp(
            endpoints: Self.endpointsGenerated,  // 자동 생성!
            networkService: networkService,
            appTitle: "MyAPI API Documentation"
        )
    }
}
```

## 🚀 완전 자동화

생성된 앱은:
- ✅ 빌드 시 자동으로 타입 등록 코드 생성
- ✅ 빌드 시 자동으로 Endpoints 딕셔너리 생성
- ✅ 새 타입/Request 추가 시 자동 반영
- ✅ 수동 관리 코드 0줄!

## 🛠 트러블슈팅

### 스크립트 경로 오류

생성된 Project.swift의 `SCRIPTS_DIR` 경로가 맞지 않으면:

```bash
swift Scripts/CreateDocKitExample.swift \
    --name MyAPIDocKitExample \
    --sources Projects/MyAPI/Sources \
    --output Projects/MyAPIDocKitExample \
    --scripts ../../../Scripts  # 상대 경로 조정
```

### 소스 경로 확인

생성 후 `<output>/README.md`에서 소스 경로가 올바른지 확인:

```markdown
1. **TypeRegistration+Generated.swift**
   - 소스 경로: Projects/MyAPI/Sources  # 이 경로 확인
```

### 수동 코드 생성 테스트

빌드 스크립트가 작동하지 않으면 수동으로 테스트:

```bash
cd <output>

# TypeRegistration 생성 테스트
swift <scripts-path>/GenerateTypeRegistration.swift \
    --project "<sources>" \
    --output "<appName>/Sources/TypeRegistration+Generated.swift" \
    --module "<appName>" \
    --target "<appName>App"

# Endpoints 생성 테스트
swift <scripts-path>/GenerateEndpoints.swift \
    --project "<sources>" \
    --output "<appName>/Sources/Endpoints+Generated.swift" \
    --module "<appName>" \
    --target "<appName>App"
```

## 📚 관련 문서

- [GenerateTypeRegistration.swift](README.md#-generatetyperegistrationswift)
- [GenerateEndpoints.swift](README.md#-generateendpointsswift)
- [AsyncNetworkDocKit](../Projects/AsyncNetworkDocKit/README.md)


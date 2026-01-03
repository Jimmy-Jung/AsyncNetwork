# 📝 자동 코드 생성 스크립트

이 디렉토리에는 AsyncNetwork 프로젝트의 반복적인 코드를 자동으로 생성하는 스크립트가 포함되어 있습니다.

## 📦 포함된 파일

1. **`GenerateTypeRegistration.swift`**: `@DocumentedType` 타입 등록 코드 자동 생성
2. **`GenerateEndpoints.swift`**: `@APIRequest` Endpoints 딕셔너리 자동 생성

---

## 🔧 1. GenerateTypeRegistration.swift

### 기능
`@DocumentedType`이 적용된 모든 타입을 스캔하여 자동으로 등록하는 코드를 생성합니다.

### 사용 방법

#### 수동 실행

```bash
cd AsyncNetwork

# 기본 실행
Scripts/GenerateTypeRegistration.swift \
  --project Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources \
  --output Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources/TypeRegistration+Generated.swift

# Verbose 모드
Scripts/GenerateTypeRegistration.swift \
  --project Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources \
  --output Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources/TypeRegistration+Generated.swift \
  --verbose
```

#### 생성되는 코드

```swift
extension AsyncNetworkDocKitExampleApp {
    func registerAllTypesGenerated() {
        _ = Address.typeStructure
        _ = Album.typeStructure
        _ = Author.typeStructure
        // ... (모든 @DocumentedType 타입)
    }
}
```

---

## 🔧 2. GenerateEndpoints.swift

### 기능
`@APIRequest`가 적용된 모든 Request 타입을 스캔하여 Endpoints 딕셔너리를 자동으로 생성합니다.

### 사용 방법

#### 수동 실행

```bash
cd AsyncNetwork

# 기본 실행
Scripts/GenerateEndpoints.swift \
  --project Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources \
  --output Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources/Endpoints+Generated.swift

# Verbose 모드
Scripts/GenerateEndpoints.swift \
  --project Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources \
  --output Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources/Endpoints+Generated.swift \
  --verbose
```

#### 생성되는 코드

```swift
extension AsyncNetworkDocKitExampleApp {
    static var endpointsGenerated: [String: [EndpointMetadata]] {
        [
            "Posts": [
                GetAllPostsRequest.metadata,
                GetPostByIdRequest.metadata,
                // ...
            ],
            "Users": [
                GetAllUsersRequest.metadata,
                // ...
            ],
            // ... (모든 카테고리)
        ]
    }
}
```

---

## 🎯 Tuist Project.swift 통합 (권장)

Tuist를 사용하는 경우 `Project.swift`에 직접 스크립트를 추가할 수 있습니다.

### Project.swift 설정

```swift
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "AsyncNetworkDocKitExample",
    targets: [
        .target(
            name: "AsyncNetworkDocKitExample",
            // ... 다른 설정 ...
            scripts: [
                // 자동 코드 생성 스크립트
                .pre(
                    script: """
                    set -e
                    
                    SCRIPTS_DIR="${SRCROOT}/../../Scripts"
                    PROJECT_SOURCE="${SRCROOT}/AsyncNetworkDocKitExample/Sources"
                    OUTPUT_DIR="${SRCROOT}/AsyncNetworkDocKitExample/Sources"
                    
                    echo "🔄 Generating code..."
                    
                    # 1. TypeRegistration 생성
                    if [ -f "$SCRIPTS_DIR/GenerateTypeRegistration.swift" ]; then
                        echo "  📝 Generating type registration..."
                        # macOS SDK를 사용하여 Swift 스크립트 실행
                        xcrun --sdk macosx swift "$SCRIPTS_DIR/GenerateTypeRegistration.swift" \\
                            --project "$PROJECT_SOURCE" \\
                            --output "$OUTPUT_DIR/TypeRegistration+Generated.swift" \\
                            --module "AsyncNetworkDocKitExample" \\
                            --target "AsyncNetworkDocKitExampleApp"
                        
                        if [ $? -eq 0 ]; then
                            echo "  ✅ Type registration generated"
                        else
                            echo "  ❌ Failed to generate type registration"
                            exit 1
                        fi
                    else
                        echo "  ⚠️  TypeRegistration script not found"
                    fi
                    
                    # 2. Endpoints 생성
                    if [ -f "$SCRIPTS_DIR/GenerateEndpoints.swift" ]; then
                        echo "  📝 Generating endpoints..."
                        # macOS SDK를 사용하여 Swift 스크립트 실행
                        xcrun --sdk macosx swift "$SCRIPTS_DIR/GenerateEndpoints.swift" \\
                            --project "$PROJECT_SOURCE" \\
                            --output "$OUTPUT_DIR/Endpoints+Generated.swift" \\
                            --module "AsyncNetworkDocKitExample" \\
                            --target "AsyncNetworkDocKitExampleApp"
                        
                        if [ $? -eq 0 ]; then
                            echo "  ✅ Endpoints generated"
                        else
                            echo "  ❌ Failed to generate endpoints"
                            exit 1
                        fi
                    else
                        echo "  ⚠️  Endpoints script not found"
                    fi
                    
                    echo "✨ Code generation completed"
                    """,
                    name: "Generate Code",
                    basedOnDependencyAnalysis: false
                ),
            ],
            // ... 다른 설정 ...
        ),
    ]
)
```

### Tuist 프로젝트 재생성

```bash
cd Projects/AsyncNetworkDocKitExample
tuist generate
```

---

## 🎯 Xcode Build Phase 통합 (Tuist 미사용 시)

두 스크립트를 빌드 시 자동으로 실행하도록 설정할 수 있습니다.

### 1단계: Xcode에서 Build Phase 추가

1. Xcode에서 `AsyncNetworkDocKitExample` 프로젝트 열기
2. `AsyncNetworkDocKitExample` 타겟 선택
3. **Build Phases** 탭 이동
4. **+** → **New Run Script Phase** 선택
5. 스크립트 이름을 "Generate Code"로 변경
6. **Compile Sources** 이전으로 드래그

### 2단계: 스크립트 입력

```bash
#!/bin/bash

set -e  # 에러 발생 시 중단

# 경로 설정
SCRIPTS_DIR="${PROJECT_DIR}/../../Scripts"
PROJECT_SOURCE="${PROJECT_DIR}/Sources"
OUTPUT_DIR="${PROJECT_DIR}/Sources"

echo "🔄 Generating code..."

# 1. TypeRegistration 생성
if [ -f "$SCRIPTS_DIR/GenerateTypeRegistration.swift" ]; then
    echo "  📝 Generating type registration..."
    # macOS SDK를 사용하여 Swift 스크립트 실행
    xcrun --sdk macosx swift "$SCRIPTS_DIR/GenerateTypeRegistration.swift" \
        --project "$PROJECT_SOURCE" \
        --output "$OUTPUT_DIR/TypeRegistration+Generated.swift" \
        --module "AsyncNetworkDocKitExample" \
        --target "AsyncNetworkDocKitExampleApp"
    
    if [ $? -eq 0 ]; then
        echo "  ✅ Type registration generated"
    else
        echo "  ❌ Failed to generate type registration"
        exit 1
    fi
else
    echo "  ⚠️  TypeRegistration script not found"
fi

# 2. Endpoints 생성
if [ -f "$SCRIPTS_DIR/GenerateEndpoints.swift" ]; then
    echo "  📝 Generating endpoints..."
    # macOS SDK를 사용하여 Swift 스크립트 실행
    xcrun --sdk macosx swift "$SCRIPTS_DIR/GenerateEndpoints.swift" \
        --project "$PROJECT_SOURCE" \
        --output "$OUTPUT_DIR/Endpoints+Generated.swift" \
        --module "AsyncNetworkDocKitExample" \
        --target "AsyncNetworkDocKitExampleApp"
    
    if [ $? -eq 0 ]; then
        echo "  ✅ Endpoints generated"
    else
        echo "  ❌ Failed to generate endpoints"
        exit 1
    fi
else
    echo "  ⚠️  Endpoints script not found"
fi

echo "✨ Code generation completed"
```

### 3단계: 캐싱 최적화 (선택적)

**Input Files** 추가:
```
$(SRCROOT)/Sources/Models.swift
$(SRCROOT)/Sources/APIRequests.swift
```

**Output Files** 추가:
```
$(SRCROOT)/Sources/TypeRegistration+Generated.swift
$(SRCROOT)/Sources/Endpoints+Generated.swift
```

---

## 📚 옵션 설명

두 스크립트 모두 동일한 옵션을 사용합니다:

| 옵션 | 짧은 형식 | 설명 | 필수 |
|-----|---------|------|------|
| `--project` | `-p` | 프로젝트 소스 디렉토리 경로 | ✅ |
| `--output` | `-o` | 출력 파일 경로 | ✅ |
| `--module` | `-m` | 모듈 이름 | ❌ (기본: AsyncNetworkDocKitExample) |
| `--target` | `-t` | 타겟 이름 | ❌ (기본: AsyncNetworkDocKitExampleApp) |
| `--verbose` | `-v` | 상세 출력 활성화 | ❌ |
| `--help` | `-h` | 도움말 표시 | ❌ |

---

## 🔍 작동 원리

### GenerateTypeRegistration.swift

1. **스캔**: 프로젝트의 모든 `.swift` 파일을 재귀적으로 스캔
2. **추출**: `@DocumentedType` 다음 줄에서 타입 이름 추출
3. **생성**: `registerAllTypesGenerated()` 메서드 생성
4. **저장**: `TypeRegistration+Generated.swift` 파일로 저장

### GenerateEndpoints.swift

1. **스캔**: 프로젝트의 모든 `.swift` 파일을 재귀적으로 스캔
2. **추출**: `@APIRequest` 블록에서 tags와 struct 이름 추출
3. **그룹화**: 첫 번째 tag를 기준으로 카테고리별 그룹화
4. **생성**: `endpointsGenerated` 프로퍼티 생성
5. **저장**: `Endpoints+Generated.swift` 파일로 저장

---

## ✅ 장점

### 공통

1. **완전 자동화**: 타입/Request 추가 시 빌드만 하면 자동 업데이트
2. **수동 관리 불필요**: 반복적인 코드를 직접 수정할 필요 없음
3. **타입 안전**: Swift 컴파일러가 타입 체크
4. **외부 의존성 없음**: Swift만 사용

### GenerateTypeRegistration.swift
- 37개 타입을 수동으로 관리할 필요 없음
- 타입 누락 방지

### GenerateEndpoints.swift
- 16개 Endpoint를 7개 카테고리로 자동 분류
- tags 기반 자동 카테고리화
- Request 추가 시 자동으로 endpoints에 포함

---

## ⚠️ 주의사항

### 공통

1. **Generated 파일 제외**: 스크립트는 `/Generated/` 폴더와 `+Generated.swift` 파일을 자동으로 제외합니다
2. **Build Phase 순서**: "Compile Sources" 이전에 실행되어야 합니다
3. **경로 설정**: Xcode Build Phase에서 경로를 프로젝트 구조에 맞게 조정하세요

### GenerateEndpoints.swift

1. **tags 필수**: `@APIRequest`에 `tags` 파라미터가 필요합니다
2. **카테고리 결정**: 첫 번째 tag가 카테고리명이 됩니다
3. **정렬**: 카테고리와 Request 모두 알파벳 순으로 정렬됩니다

---

## 🎨 .gitignore 설정

생성된 파일을 Git에서 제외하려면:

```gitignore
# Auto-generated files
**/TypeRegistration+Generated.swift
**/Endpoints+Generated.swift
```

또는 생성된 파일을 커밋하려면 `.gitignore`에 추가하지 마세요.

---

## 🐛 문제 해결

### 스크립트 실행 권한 오류

```bash
chmod +x Scripts/GenerateTypeRegistration.swift
chmod +x Scripts/GenerateEndpoints.swift
```

### 타입/Request를 찾을 수 없음

- `--verbose` 옵션으로 상세 출력 확인
- 프로젝트 경로가 올바른지 확인
- `@DocumentedType` / `@APIRequest` 어노테이션이 정확히 작성되었는지 확인

### 빌드 시 에러

- Output Files 설정이 올바른지 확인
- 생성된 파일이 프로젝트에 추가되었는지 확인
- `import AsyncNetworkCore` / `import AsyncNetworkDocKit`가 가능한지 확인

---

## 📖 추가 자료

- [Swift Scripting Guide](https://www.swift.org/getting-started/#using-the-package-manager)
- [Xcode Build Phase Documentation](https://developer.apple.com/documentation/xcode/customizing-the-build-phases-of-a-target)
- [AsyncNetwork Documentation](../README.md)

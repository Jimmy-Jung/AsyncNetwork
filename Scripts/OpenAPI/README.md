# OpenAPI 문서 생성 스크립트

`@APIRequest`로 정의된 API를 OpenAPI 3.0 스펙으로 변환하고, 다양한 형식의 HTML 문서를 생성합니다.

---

## 📊 스크립트 목록

| 스크립트 | 기능 | 입력 | 출력 |
|---------|------|------|------|
| `ExportOpenAPI.swift` | OpenAPI 스펙 생성 | Swift 소스 | `openapi.json/yaml` |
| `GenerateAPIDocs.swift` | Redoc HTML | `openapi.json` | `api-docs-redoc.html` |
| `GenerateSwaggerUI.swift` | Swagger UI HTML | `openapi.json` | `api-docs-swagger.html` |
| `GenerateStoplightElements.swift` | Stoplight HTML | `openapi.json` | `api-docs-elements.html` |
| `generate-docs.sh` | 통합 자동화 | - | 위 4개 모두 |

---

## 🚀 빠른 시작

### 방법 1: 통합 스크립트 (권장)

```bash
cd /path/to/AsyncNetwork
./Scripts/OpenAPI/generate-docs.sh
```

**생성되는 파일**:
- `openapi.json` - OpenAPI 3.0 스펙
- `api-docs-redoc.html` - Redoc (아름다운 디자인)
- `api-docs-swagger.html` - Swagger UI (API 테스트)
- `api-docs-elements.html` - Stoplight Elements 🌟

### 방법 2: 개별 실행

```bash
# 1. OpenAPI 스펙 생성
swift Scripts/OpenAPI/ExportOpenAPI.swift \
    --project Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources \
    --output ./openapi.json \
    --title "AsyncNetwork API" \
    --version "1.0.0"

# 2. HTML 문서 생성 (선택)
swift Scripts/OpenAPI/GenerateAPIDocs.swift openapi.json api-docs-redoc.html
swift Scripts/OpenAPI/GenerateSwaggerUI.swift openapi.json api-docs-swagger.html
swift Scripts/OpenAPI/GenerateStoplightElements.swift openapi.json api-docs-elements.html
```

---

## 📖 ExportOpenAPI.swift

### 기능
- ✅ Swift 소스 파일에서 `@APIRequest` 직접 파싱
- ✅ Property Wrappers 자동 추출 (`@PathParameter`, `@QueryParameter`, `@HeaderField`, `@CustomHeader`, `@RequestBody`)
- ✅ Default 값 자동 포함
- ✅ baseURL 변수 자동 변환
- ✅ Path별 Operation 자동 병합
- ✅ JSON/YAML 형식 지원

### 사용법

```bash
swift Scripts/OpenAPI/ExportOpenAPI.swift [옵션]
```

### 옵션

| 옵션 | 단축 | 설명 | 기본값 |
|------|------|------|--------|
| `--project` | `-p` | @APIRequest 경로 (여러 개 가능) | 대화형 입력 |
| `--output` | `-o` | 출력 파일 경로 | `./openapi.json` |
| `--format` | `-f` | 출력 형식 (json/yaml) | `json` |
| `--title` | `-t` | API 제목 | "API Documentation" |
| `--version` | `-v` | API 버전 | "1.0.0" |
| `--description` | `-d` | API 설명 | - |
| `--help` | `-h` | 도움말 표시 | - |

### 예시

```bash
# 대화형 모드
swift Scripts/OpenAPI/ExportOpenAPI.swift

# 명령줄 모드
swift Scripts/OpenAPI/ExportOpenAPI.swift \
    --project Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources \
    --output ./docs/openapi.json \
    --format json \
    --title "My API" \
    --version "2.0.0" \
    --description "완벽한 API 문서"

# 여러 경로 지정
swift Scripts/OpenAPI/ExportOpenAPI.swift \
    --project Sources/Network \
    --project Sources/API \
    --project Sources/Data \
    --output ./openapi.json
```

---

## 📄 GenerateAPIDocs.swift (Redoc)

### 특징
- 📖 읽기 전용 문서
- 🎨 아름답고 깔끔한 UI
- 📱 모바일 친화적
- 🔍 강력한 검색 기능

### 사용법

```bash
swift Scripts/OpenAPI/GenerateAPIDocs.swift <openapi.json> <출력.html>
```

### 예시

```bash
swift Scripts/OpenAPI/GenerateAPIDocs.swift openapi.json api-docs-redoc.html
open api-docs-redoc.html
```

---

## 🧪 GenerateSwaggerUI.swift (Swagger UI)

### 특징
- ⚡ API 테스트 가능 (Execute 버튼)
- 🔧 인터랙티브 문서
- 🧪 개발자 테스트용
- 📝 요청/응답 실시간 확인

### 사용법

```bash
swift Scripts/OpenAPI/GenerateSwaggerUI.swift <openapi.json> <출력.html>
```

### 예시

```bash
swift Scripts/OpenAPI/GenerateSwaggerUI.swift openapi.json api-docs-swagger.html
open api-docs-swagger.html
```

---

## 💎 GenerateStoplightElements.swift (Stoplight Elements)

### 특징
- 🎨 Redoc의 아름다움 + Swagger의 인터랙션
- 💎 최고급 UI/UX
- 📚 공개 문서용 최적
- 🌟 **가장 추천!**

### 사용법

```bash
swift Scripts/OpenAPI/GenerateStoplightElements.swift <openapi.json> <출력.html>
```

### 예시

```bash
swift Scripts/OpenAPI/GenerateStoplightElements.swift openapi.json api-docs-elements.html
open api-docs-elements.html
```

---

## 🔧 고급 사용법

### baseURL 변수 커스터마이징

`ExportOpenAPI.swift` 파일 수정:

```swift
// 142-149줄
func extractBaseURLs(from requests: [APIRequestInfo]) -> [String: String] {
    var map: [String: String] = [:]
    
    map["jsonPlaceholderURL"] = "https://jsonplaceholder.typicode.com"
    map["apiExampleURL"] = "https://api.example.com"
    map["myProductionAPI"] = "https://api.myapp.com/v1"  // ← 추가
    
    return map
}
```

### CI/CD 통합

```yaml
# .github/workflows/docs.yml
name: Generate API Docs

on:
  push:
    branches: [main]

jobs:
  docs:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Generate OpenAPI Docs
        run: |
          ./Scripts/OpenAPI/generate-docs.sh
      
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./
          files: |
            openapi.json
            api-docs-*.html
```

---

## 🎯 문서 형식 비교

| 기능 | Redoc | Swagger UI | Stoplight Elements |
|------|-------|------------|-------------------|
| 읽기 전용 문서 | ✅ | ✅ | ✅ |
| API 테스트 | ❌ | ✅ | ✅ |
| 아름다운 UI | ✅ | ⚠️ | ✅✅ |
| 코드 예시 | ✅ | ✅ | ✅ |
| 다크 모드 | ✅ | ✅ | ✅ |
| 모바일 최적화 | ✅ | ⚠️ | ✅ |
| 검색 기능 | ✅ | ✅ | ✅ |
| **추천 용도** | 내부 문서 | 개발자 테스트 | 공개 문서 🌟 |

---

## 📂 출력 파일 구조

```
AsyncNetwork/
├── openapi.json              # OpenAPI 3.0 스펙
├── api-docs-redoc.html       # Redoc
├── api-docs-swagger.html     # Swagger UI
└── api-docs-elements.html    # Stoplight Elements
```

---

## 🔍 문제 해결

### 1. "파일을 찾을 수 없습니다"
```bash
# 경로 확인
ls -la Projects/AsyncNetworkDocKitExample/AsyncNetworkDocKitExample/Sources/

# 절대 경로 사용
swift Scripts/OpenAPI/ExportOpenAPI.swift \
    --project /Users/username/MyProject/Sources
```

### 2. "baseURL이 변수명으로 표시됨"
```swift
// ExportOpenAPI.swift의 extractBaseURLs()에 매핑 추가
map["yourBaseURLVar"] = "https://actual.url.com"
```

### 3. "Default 값이 표시되지 않음"
```swift
// Property Wrapper에 기본값 명시 필요
@QueryParameter var page: Int? = 1
@CustomHeader("X-Version") var version: String? = "1.0.0"
```

### 4. "HTML이 제대로 렌더링되지 않음"
```bash
# Stoplight Elements는 openapi.json과 같은 폴더에 있어야 함
mv api-docs-elements.html ./  # openapi.json이 있는 위치로
```

---

## 🌐 외부 도구 연동

### Postman
```bash
# 1. OpenAPI 생성
swift Scripts/OpenAPI/ExportOpenAPI.swift --output openapi.json

# 2. Postman 열기
# File → Import → openapi.json 선택
```

### Insomnia
```bash
# Insomnia → Preferences → Data → Import Data → openapi.json
```

### 라이브 프리뷰 (Node.js)
```bash
npx @redocly/cli preview-docs openapi.json
```

### 로컬 HTTP 서버
```bash
# Python
python3 -m http.server 8000
# → http://localhost:8000/api-docs-elements.html

# Node.js
npx http-server -p 8000 -o api-docs-elements.html
```

---

**Made with ❤️ by AsyncNetwork Team**


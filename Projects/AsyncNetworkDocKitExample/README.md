# AsyncNetworkDocKitExample

AsyncNetworkDocKit을 사용한 API 문서 샘플 앱입니다.

## 🎯 개요

이 프로젝트는 AsyncNetworkDocKit의 실제 사용 예시를 보여줍니다:

- ✅ 16개의 API 엔드포인트 문서화
- ✅ 7개 카테고리로 분류 (Posts, Users, Comments, Albums, Photos, Todos, Users Extended)
- ✅ 실시간 API 테스트 기능
- ✅ 자동 코드 생성 (TypeRegistration, Endpoints)

## 🚀 실행 방법

### 1. Tuist 프로젝트 생성

```bash
cd AsyncNetwork
tuist generate
```

### 2. Xcode에서 열기

```bash
open AsyncNetwork.xcworkspace
```

### 3. 스킴 선택 및 실행

- **AsyncNetworkDocKitExample** 스킴 선택
- **Cmd + R**로 실행

## 📁 프로젝트 구조

```
AsyncNetworkDocKitExample/
├── Sources/
│   ├── AsyncNetworkDocKitExampleApp.swift    # 메인 앱
│   ├── APIRequests.swift                      # @APIRequest 정의 (16개)
│   ├── Models.swift                           # @DocumentedType 정의 (37개)
│   ├── TypeRegistration+Generated.swift      # 자동 생성 (빌드 시)
│   └── Endpoints+Generated.swift              # 자동 생성 (빌드 시)
├── Resources/
│   └── Assets.xcassets/
└── README.md
```

## 🔄 자동 코드 생성

빌드 시 다음 파일들이 자동으로 생성됩니다:

### TypeRegistration+Generated.swift

```swift
extension AsyncNetworkDocKitExampleApp {
    func registerAllTypesGenerated() {
        _ = Address.typeStructure
        _ = Album.typeStructure
        // ... (37개 타입)
    }
}
```

### Endpoints+Generated.swift

```swift
extension AsyncNetworkDocKitExampleApp {
    static var endpointsGenerated: [String: [EndpointMetadata]] {
        [
            "Posts": [
                GetAllPostsRequest.metadata,
                GetPostByIdRequest.metadata,
                // ...
            ],
            // ... (7개 카테고리)
        ]
    }
}
```

## 📚 주요 기능

### 1. 3열 레이아웃

- **1열**: API 리스트 (카테고리별 분류)
- **2열**: API 상세 정보 (경로, 파라미터, 응답)
- **3열**: 실시간 테스터 (파라미터 입력 후 즉시 요청)

### 2. 실시간 API 테스트

- 파라미터 입력 UI 자동 생성
- 요청/응답 실시간 표시
- JSON 포맷팅 및 구문 강조

### 3. 검색 기능

- API 경로 검색
- API 타이틀 검색
- 실시간 필터링

### 4. 다크모드 지원

- 자동 라이트/다크 테마 전환
- 시스템 설정 연동

## 🛠 수동 코드 생성 (디버깅용)

빌드 시 자동으로 생성되지만, 수동으로 실행하려면:

```bash
# TypeRegistration 생성
swift ../../Scripts/GenerateTypeRegistration.swift \
    --project AsyncNetworkDocKitExample/Sources \
    --output AsyncNetworkDocKitExample/Sources/TypeRegistration+Generated.swift \
    --module "AsyncNetworkDocKitExample" \
    --target "AsyncNetworkDocKitExampleApp"

# Endpoints 생성
swift ../../Scripts/GenerateEndpoints.swift \
    --project AsyncNetworkDocKitExample/Sources \
    --output AsyncNetworkDocKitExample/Sources/Endpoints+Generated.swift \
    --module "AsyncNetworkDocKitExample" \
    --target "AsyncNetworkDocKitExampleApp"
```

## 📖 더 알아보기

- [AsyncNetwork README](../../README.md) - 메인 문서
- [Scripts README](../../Scripts/README.md) - 스크립트 상세 설명
- [GitHub Repository](https://github.com/Jimmy-Jung/AsyncNetwork)

---

**Made with ❤️ by AsyncNetwork Team**

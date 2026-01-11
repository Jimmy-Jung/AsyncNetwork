# API Playground (SwiftUI Version)

AsyncNetworkDocKit의 우수한 구조를 참고하여 구현한 SwiftUI 기반 API Playground입니다.

## 📋 목차

- [개요](#개요)
- [주요 기능](#주요-기능)
- [아키텍처](#아키텍처)
- [파일 구조](#파일-구조)
- [사용 방법](#사용-방법)
- [기술 스택](#기술-스택)
- [개선 사항](#개선-사항)
- [변경 로그](#변경-로그)

---

## 🎯 개요

AsyncNetworkDocKit의 3열 레이아웃과 우수한 UX를 참고하여, AsyncViewModel과 통합한 완전한 SwiftUI 기반 API Playground를 구현했습니다.

### 기존 UIKit Playground vs 새로운 SwiftUI Playground

| 항목 | UIKit Playground | SwiftUI Playground |
|-----|-----------------|-------------------|
| UI 프레임워크 | UIKit | SwiftUI |
| 레이아웃 | Split View (2열) | NavigationSplitView (3열) |
| 상태 관리 | AsyncViewModel | AsyncViewModel + Observation |
| 코드 라인 수 | ~1,200줄 | ~600줄 |
| 메타데이터 표시 | 제한적 | 상세 (타임스탬프, 크기, 헤더 등) |
| UI 스타일 | 기본 | DocKit 스타일 (이모지, Label with SF Symbols) |

---

## ✨ 주요 기능

### 1. 3열 레이아웃 (NavigationSplitView)

```
┌─────────────┬────────────────┬──────────────────┐
│  API 리스트  │  API 상세 정보  │  API 테스터      │
│             │                │                  │
│ • GET       │ • 설명         │ • Try It Out     │
│ • POST      │ • 파라미터     │ • Request        │
│ • PUT       │ • Request Body │ • Response       │
│ • DELETE    │ • Response     │ • Metadata       │
└─────────────┴────────────────┴──────────────────┘
```

**1열: API 리스트**
- 모든 HTTP 메서드 표시
- 검색 기능
- HTTPMethodBadge로 메서드 시각화
- DocKit 스타일 레이아웃

**2열: API 상세 정보**
- Label with SF Symbols
- API 설명 및 태그
- 엔드포인트 정보 상세 표시
- Try API Tester 버튼 (iPhone compact 모드)

**3열: API 테스터**
- 실시간 API 테스트
- 헤더 편집 가능
- 파라미터 입력
- Request/Response 메타데이터 상세 표시

### 2. Request/Response 메타데이터 시각화 (DocKit 스타일)

AsyncNetworkDocKit의 우수한 메타데이터 표시를 완벽히 구현:

```swift
🌐 REQUEST
🕐 14:23:45.123

🔧 Method & URL:
GET https://jsonplaceholder.typicode.com/posts

📋 Headers:
Content-Type: application/json; charset=utf-8
Accept: application/json

🔑 Parameters:
id = 1
userId = 1

📦 Body (245 bytes):
{
  "userId": 1,
  "title": "Sample Post"
}

✅ RESPONSE
🕐 14:23:45.456

📊 Status: 200

📋 Response Headers:
Content-Type: application/json; charset=utf-8
Content-Length: 1234

📦 Response Body (1.2 KB):
[
  {
    "id": 1,
    "userId": 1,
    "title": "Sample Post"
  }
]
```

### 3. State 지속성 (StateStore)

각 API 메서드별로 상태를 독립적으로 관리:

- API 전환 시 이전 입력 값 유지
- 테스트 결과 히스토리 보존
- 메모리 효율적인 State 관리
- APIPlaygroundStateStore로 중앙 관리

### 4. AsyncViewModel 통합

완벽한 단방향 데이터 흐름:

```
View → Input → Action → Reduce → State 업데이트 → View 리렌더링
```

---

## 🏗 아키텍처

### Observation + AsyncViewModel 패턴

```
┌────────────────────────────────────────────┐
│         APIPlaygroundSwiftView             │
│  (3열 NavigationSplitView)                 │
│                                            │
│  ┌──────────┬──────────────┬─────────────┐│
│  │ List     │ Detail       │ Tester      ││
│  │ View     │ View         │ View        ││
│  └──────────┴──────────────┴─────────────┘│
└────────────────────────────────────────────┘
               ↓ State 구독
┌────────────────────────────────────────────┐
│   APIPlaygroundSwiftViewModel              │
│   (@AsyncViewModel)                        │
│                                            │
│   Input → Action → Reduce → State         │
└────────────────────────────────────────────┘
               ↓
┌────────────────────────────────────────────┐
│   APIPlaygroundState (@Observable)         │
│   (각 API 메서드별 독립 상태)               │
│                                            │
│   • parameters, headers, body              │
│   • response, statusCode, error            │
│   • requestTimestamp, responseTimestamp    │
│   • requestBodySize, responseBodySize      │
└────────────────────────────────────────────┘
               ↓
┌────────────────────────────────────────────┐
│   APIPlaygroundStateStore                  │
│   (상태 지속성 관리)                        │
└────────────────────────────────────────────┘
```

### 데이터 흐름

1. **사용자 이벤트** → View에서 Input 발생
2. **ViewModel.send(Input)** → Input을 Action으로 변환
3. **reduce()** → State 변경 및 Effect 반환
4. **State 업데이트** → @Published로 View 리렌더링
5. **Effect 실행** → 비동기 작업 처리

---

## 📁 파일 구조

```
APIPlaygroundSwift/
├── Models/
│   └── APIPlaygroundState.swift           # Observation 기반 상태 관리
│
├── Components/
│   ├── HTTPMethodBadge.swift             # HTTP 메서드 배지
│   └── CodeBlock.swift                   # 코드 블록 표시 (DocKit 스타일)
│
├── Views/
│   ├── APIMethodListView.swift           # 1열: API 리스트 (DocKit 스타일)
│   ├── APIRequestDetailView.swift        # 2열: API 상세 정보 (DocKit 스타일)
│   └── APIRequestTesterView.swift        # 3열: API 테스터 (DocKit 스타일)
│
├── APIPlaygroundSwiftView.swift          # 메인 3열 레이아웃
├── APIPlaygroundSwiftViewModel.swift     # AsyncViewModel
├── APIPlaygroundSwiftViewController.swift # UIKit 브릿지
└── README.md                             # 이 문서
```

---

## 🚀 사용 방법

### 1. 앱 실행

```bash
# Tuist 프로젝트 생성
cd AsyncNetwork
tuist generate

# Xcode에서 실행
open AsyncNetwork.xcworkspace
```

### 2. SwiftUI Playground 탭 선택

메인 탭바에서 "SwiftUI" 탭을 선택합니다.

### 3. API 테스트

1. **1열에서 API 선택**: GET, POST, PUT, DELETE 등
2. **2열에서 상세 정보 확인**: API 설명, 파라미터, 예제
3. **3열에서 테스트 실행**:
   - 헤더 편집 (기본값 제공)
   - 파라미터 입력 (기본값 제공)
   - Request Body 작성 (POST/PUT)
   - "Send Request" 버튼 클릭
   - Response 확인

### 4. 메타데이터 확인

Request/Response 섹션에서 다음 정보 확인:
- 타임스탬프 (HH:mm:ss.SSS)
- HTTP 상태 코드 (색상 구분)
- Headers (요청/응답)
- Body 크기 (bytes)
- 전체 Request/Response 본문

---

## 🛠 기술 스택

### Core Technologies

- **SwiftUI**: 선언적 UI 프레임워크
- **AsyncViewModel**: 단방향 데이터 흐름
- **Observation**: iOS 17+ 상태 관리
- **Swift Concurrency**: async/await

### Architecture Patterns

- **MVVM**: Model-View-ViewModel
- **Unidirectional Data Flow**: Input → Action → Reduce → State
- **State Persistence**: StateStore 패턴

### Testing

- **Swift Testing**: @Test, #expect
- **AsyncTestStore**: AsyncViewModel 테스트

---

## 📈 개선 사항

### AsyncNetworkDocKit 스타일 완벽 적용

| 기능 | DocKit | 개선 전 | 개선 후 |
|-----|--------|--------|--------|
| 3열 레이아웃 | ✅ | ✅ | ✅ |
| Label with SF Symbols | ✅ | ❌ | ✅ |
| 이모지 아이콘 | ✅ | ❌ | ✅ |
| Request 메타데이터 표시 | ✅ | 제한적 | ✅ |
| Response 메타데이터 표시 | ✅ | 제한적 | ✅ |
| 타임스탬프 표시 | ✅ | ❌ | ✅ |
| Body 크기 표시 | ✅ | ❌ | ✅ |
| 헤더 편집 가능 | ✅ | ❌ | ✅ |
| 상태 지속성 | ✅ | ❌ | ✅ |
| AsyncViewModel 통합 | ❌ | ✅ | ✅ |

### 주요 개선 포인트 (2026/01/11)

1. **APIRequestTesterView 완전 재작성**
   - DocKit의 APITesterView 스타일 완벽 적용
   - Request/Response 메타데이터 섹션 강화
   - 이모지 아이콘으로 가독성 향상 (🌐, 🕐, 🔧, 📋, 🔑, 📦, ✅, ⚠️, 📊)
   - Label with SF Symbols 적용
   - 헤더 편집 기능 추가
   - 상태 지속성 (APIPlaygroundStateStore)

2. **APIRequestDetailView 개선**
   - DocKit의 EndpointDetailView 스타일 적용
   - Label with SF Symbols 사용
   - 태그 표시 개선
   - Try API Tester 버튼 (iPhone compact 모드)
   - 엔드포인트 정보 상세 표시

3. **APIMethodListView 개선**
   - DocKit의 EndpointListView 스타일 적용
   - HTTPMethodBadge 우선 표시
   - path를 monospaced 폰트로 표시
   - 검색 기능 개선

4. **CodeBlock 컴포넌트 개선**
   - DocKit 스타일 적용
   - 배경색 및 패딩 조정
   - maxHeight 사용

### 기존 UIKit Playground와 비교

**개선된 점:**

1. **3열 레이아웃**: 더 넓은 화면 활용, 정보 밀도 증가
2. **DocKit 스타일 UI**: Label with SF Symbols, 이모지 아이콘
3. **메타데이터 시각화**: 타임스탬프, 바디 크기, 헤더 상세 표시
4. **상태 지속성**: API 전환 시 입력 값 유지
5. **헤더 편집 가능**: 헤더 값 동적 수정
6. **코드 간결성**: UIKit 1,200줄 → SwiftUI 600줄
7. **선언적 UI**: 더 직관적이고 유지보수 용이

**유지된 점:**

1. AsyncViewModel 단방향 데이터 흐름
2. Repository 패턴
3. Dependency Injection
4. 테스트 가능한 아키텍처

---

## 🔄 변경 로그

### 2026/01/11

- ✨ AsyncNetworkDocKit 스타일 완벽 적용
- ✨ APIRequestTesterView 완전 재작성
- ✨ Request/Response 메타데이터 섹션 강화
- ✨ 이모지 아이콘 (🌐, 🕐, 🔧, 📋, 🔑, 📦, ✅, ⚠️, 📊) 추가
- ✨ Label with SF Symbols 적용
- ✨ 헤더 편집 기능 추가
- ✨ 상태 지속성 구현 (APIPlaygroundStateStore)
- ✨ APIRequestDetailView 개선
- ✨ APIMethodListView 개선
- ✨ CodeBlock 컴포넌트 개선
- 📝 README 업데이트

### 2026/01/11 (초기 버전)

- 🎉 AsyncNetworkDocKit 참고하여 초기 구현
- 🎉 3열 레이아웃 구현
- 🎉 AsyncViewModel 통합
- 🎉 Observation 기반 상태 관리

---

## 📝 참고 자료

- [AsyncViewModel 가이드](../../.cursor/rules/spec/asyncviewmodel/RULE.mdc)
- [Swift Functional 가이드](../../.cursor/rules/spec/swift-functional/RULE.mdc)
- [AsyncNetworkDocKit](../../../AsyncNetwork-main/Projects/AsyncNetworkDocKit)

---

**Made with ❤️ by AsyncNetwork Team**

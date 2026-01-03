# 📚 문서 구조

AsyncNetwork 프로젝트의 문서는 다음과 같이 구성되어 있습니다:

## 📁 주요 문서

### 1. [README.md](../README.md)
- 프로젝트 개요 및 소개
- 설치 방법
- 빠른 시작 가이드
- 주요 기능 설명
- API 문서 자동 생성 가이드
- 고급 기능
- 테스트
- 기여 가이드

### 2. [Scripts/README.md](../Scripts/README.md)
- CreateDocKitExample.swift 사용법
- GenerateTypeRegistration.swift 사용법
- GenerateEndpoints.swift 사용법
- 문제 해결 가이드
- 통합 워크플로우

### 3. [Projects/AsyncNetworkDocKitExample/README.md](../Projects/AsyncNetworkDocKitExample/README.md)
- 예제 프로젝트 설명
- 실행 방법
- 프로젝트 구조
- 자동 코드 생성 설명

### 4. [CHANGELOG.md](../CHANGELOG.md)
- 버전별 변경사항

### 5. [CONTRIBUTING.md](../CONTRIBUTING.md)
- 기여 가이드라인
- 코드 스타일
- Pull Request 프로세스

## 🗂 문서 계층 구조

```
AsyncNetwork/
├── README.md                           # 메인 문서 (시작점)
│   ├── 설치 및 빠른 시작
│   ├── 주요 기능
│   └── API 문서 자동 생성 → Scripts/README.md 참조
│
├── Scripts/
│   └── README.md                       # 스크립트 상세 문서
│       ├── CreateDocKitExample.swift
│       ├── GenerateTypeRegistration.swift
│       └── GenerateEndpoints.swift
│
├── Projects/AsyncNetworkDocKitExample/
│   └── README.md                       # 예제 프로젝트 문서
│
├── CHANGELOG.md                        # 변경 이력
└── CONTRIBUTING.md                     # 기여 가이드
```

## 🎯 문서 찾기

### 사용자가 하고 싶은 것에 따라:

| 목적 | 참고 문서 |
|-----|---------|
| AsyncNetwork 개요 알아보기 | [README.md](../README.md) |
| 설치 및 빠른 시작 | [README.md > 설치](../README.md#-설치) |
| API 문서 앱 만들기 | [README.md > API 문서 자동 생성](../README.md#-api-문서-자동-생성-asyncnetworkdockit) |
| 스크립트 자세히 알아보기 | [Scripts/README.md](../Scripts/README.md) |
| 예제 코드 보기 | [AsyncNetworkDocKitExample](../Projects/AsyncNetworkDocKitExample) |
| 기여하고 싶음 | [CONTRIBUTING.md](../CONTRIBUTING.md) |
| 버전별 변경사항 | [CHANGELOG.md](../CHANGELOG.md) |

## 📝 문서 작성 원칙

### 중복 최소화
- 한 가지 내용은 한 곳에만 작성
- 다른 문서에서는 링크로 참조

### 명확한 계층 구조
- README.md: 개요 및 전체 가이드
- Scripts/README.md: 스크립트 상세 설명
- Example/README.md: 예제 프로젝트 설명

### 사용자 관점
- "무엇을 하고 싶은가?"에서 시작
- 빠른 시작 → 상세 설명 순서
- 실제 예제 코드 포함

---

**Last Updated**: 2026-01-03

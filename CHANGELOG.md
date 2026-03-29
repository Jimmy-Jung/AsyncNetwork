# Changelog

이 프로젝트는 Semantic Versioning을 따릅니다.

## [3.0.0] - 2026-03-29

### Breaking

- 매크로 기능 `@APIRequest`, `@ResponseTestable` 제거
- `AsyncNetworkMacros` product, macro test target, macro 전용 의존성 제거
- 샘플 앱, OpenAPI 예제, OpenAPI 생성 스크립트 제거
- 테스트 데이터 생성 전략 API 제거

### Changed

- `AsyncNetwork` product는 유지하고 내부는 코어-only 우산 모듈로 단순화
- README, CONTRIBUTING, SECURITY, 이슈 템플릿, release workflow를 현재 저장소 구조에 맞게 정리
- `import AsyncNetwork` 공개 표면 smoke test 추가

### Migration

- 매크로 기반 요청 선언을 일반 `APIRequest` 타입으로 옮겨야 합니다
- 설치 product는 그대로 `AsyncNetwork`를 사용하면 됩니다

## [2.0.0] - 2026-02-04

- Swift 6 기반 네트워킹 코어 구조 정리

## [1.3.4] - 2026-02-03

- QueryParameter 배열 타입 지원

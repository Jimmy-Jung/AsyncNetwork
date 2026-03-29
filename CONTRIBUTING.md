# Contributing

AsyncNetwork 기여 가이드입니다.

## Requirements

- Xcode 16.0+
- Swift 6.0+
- macOS 14.0+

## Local Setup

```bash
git clone https://github.com/Jimmy-Jung/AsyncNetwork.git
cd AsyncNetwork
swift build
swift test
```

## Project Layout

```text
AsyncNetwork/
├── Package.swift
├── Projects/
│   └── AsyncNetwork/
│       ├── Sources/
│       └── Tests/
└── .github/
```

## Contribution Rules

- 변경에는 가능한 한 같은 PR 안에서 테스트를 같이 추가합니다.
- 공개 API를 바꾸면 README와 CHANGELOG를 같이 수정합니다.
- 구현은 명시적으로 유지하고, 불필요한 추상화는 피합니다.

## Commit Convention

Conventional Commits 형식을 사용합니다.

```text
feat(scope): change summary
fix(scope): change summary
docs: change summary
test(scope): change summary
```

예시 scope:

- `core`
- `client`
- `service`
- `docs`

## Pull Request Checklist

- `swift build`
- `swift test`
- 필요 시 문서 업데이트
- breaking change 여부 명시

## Issues

- 버그: https://github.com/Jimmy-Jung/AsyncNetwork/issues/new?template=bug_report.yml
- 기능 제안: https://github.com/Jimmy-Jung/AsyncNetwork/issues/new?template=feature_request.yml

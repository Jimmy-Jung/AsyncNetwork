<!--
  AsyncNetworkExampleApp README
  Created by JunyoungJung on 2026/03/29.
-->

# AsyncNetwork Example App

`AsyncNetwork`의 코어 사용법을 실제 화면과 코드로 같이 보여주는 iOS 참고 앱입니다.

## 포함된 화면

- `Basics`: `APIRequest`, `@PathParameter`, `@QueryParameter`, `@RequestBody`, `@HeaderField`
- `Recipes`: 서비스 preset 활용, 인터셉터 미리보기, 재시도 데모
- `Monitor`: `NetworkMonitor` 실시간 상태와 오프라인 가드 비교

## 실행 방법

프로젝트는 생성된 [AsyncNetworkExampleApp.xcworkspace](/Users/jimmy/Documents/GitHub/AsyncNetwork/Examples/AsyncNetworkExampleApp/AsyncNetworkExampleApp.xcworkspace) 를 포함합니다.

```bash
open Examples/AsyncNetworkExampleApp/AsyncNetworkExampleApp.xcworkspace
```

프로젝트를 다시 생성해야 하면:

```bash
cd Examples/AsyncNetworkExampleApp
tuist install
tuist generate --no-open
```

## 빌드

```bash
xcodebuild -workspace Examples/AsyncNetworkExampleApp/AsyncNetworkExampleApp.xcworkspace \
  -scheme AsyncNetworkExampleApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build test
```

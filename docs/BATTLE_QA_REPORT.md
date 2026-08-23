# 전투 화면 품질 검증 보고서

검증일: 2026-08-23

## 자동 검증 결과

| 항목 | 결과 | 비고 |
|---|---|---|
| `flutter analyze` | 통과 | 정적 분석 오류 없음 |
| `flutter test` | 통과 | 순수 Dart 테스트 39개 |
| `flutter test --coverage` | 통과 | 커버리지 산출 성공 |
| Flutter Web release build | 통과 | GitHub Pages base href 포함 |
| Android Debug APK | 통과 | `build/app/outputs/flutter-apk/app-debug.apk` 생성 |
| iOS Simulator Xcode build | 통과 | `CODE_SIGNING_ALLOWED=NO`로 소스·플러그인 컴파일 확인 |
| `git diff --check` | 통과 | 공백·패치 오류 없음 |
| 전투 부대 PNG 알파 | 통과 | 보병·기병·궁병 RGBA 확인 |
| 배포 URL 로드 | 통과 | GitHub Pages 최신 배포 확인 |
| 브라우저 콘솔 | 통과 | 390×844, 375×812, 430×932에서 error/warn 없음 |

## 반응형 뷰포트 점검

배포된 Web을 다음 세로 뷰포트에서 각각 새로 로드했다.

- 390×844 기준 화면
- 375×812 작은 iPhone 계열 화면
- 430×932 큰 iPhone 계열 화면

세 환경 모두 페이지 로드가 완료되었고 브라우저 콘솔 오류가 발생하지 않았다.

## 확인된 제한

- Flutter Web의 자동 DOM 접근성 트리만으로는 Flame 전투판의 실제 픽셀 겹침과 잘림을 판정할 수 없다.
- 실제 iOS Safari와 Android Chrome 기기에서의 터치 체감, SafeArea, 60fps는 아직 수동 확인 대상이다.
- 텍스트 크기를 크게 설정한 접근성 모드의 전 화면 회귀 테스트는 아직 없다.
- 전투용 고해상도 PNG는 일부 파일이 1~3MB 수준이므로 최초 로딩 성능은 모바일 기기에서 추가 측정이 필요하다.
- `flutter build ios --no-codesign` 디바이스 패키징은 로컬 Flutter SDK 바이너리에 포함된
  `com.apple.provenance` resource fork 때문에 실패했다. 프로젝트 소스 컴파일은
  `xcodebuild ... CODE_SIGNING_ALLOWED=NO` Simulator 빌드로 통과했다.

## 다음 QA 작업

1. 실제 iOS Safari와 Android Chrome에서 전투 진입·부대 선택·명령 연타를 점검한다.
2. 시스템 글자 크기 125%와 150%에서 HUD·로그·결과 화면의 겹침을 확인한다.
3. 전투판 진입 직후 이미지 디코딩 시간과 애니메이션 프레임 드롭을 측정한다.
4. 위 결과를 바탕으로 P7을 완료 처리하고 P8 회귀 테스트로 이동한다.

# 이미지 에셋 생성·적용·구현 로드맵

작성일: 2026-08-21
기준 문서: `docs/ASSET_GAP_ANALYSIS.md`

## 1. 목표

참고 이미지의 화면 정보 밀도와 고전 전략게임 분위기를 독자적인 이미지 에셋으로 재구성한다.

최종 목표는 다음과 같다.

```text
imagegen 생성
  ↓
사람 검수·선별
  ↓
프로젝트 assets 저장
  ↓
AssetRepository key 등록
  ↓
Flutter 위젯 / Flame Component 연결
  ↓
390×844 모바일 검수
  ↓
Web·iOS·Android 빌드 검증
```

이미지 생성만 완료된 상태는 작업 완료로 보지 않는다. 실제 화면에서 `Image.asset`, `DecorationImage`, `SpriteComponent`, `SpriteAnimationComponent` 중 적절한 방식으로 사용되고, 데이터와 연결되어야 완료로 인정한다.

## 2. 작업 원칙

- 원작 그래픽·초상화·맵·폰트·문구를 복제하지 않는다.
- 모든 인물·지역·문장·아이콘은 가상 데이터와 가상 문양을 사용한다.
- 이미지에 읽을 수 있는 텍스트를 넣지 않는다. 텍스트는 Flutter가 렌더링한다.
- imagegen은 분위기·일러스트·아이콘·스프라이트 생성에 사용하고, 수치·라벨·상태·버튼 동작은 코드가 담당한다.
- 같은 묶음의 이미지는 동일한 조명·팔레트·재질·카메라 시점을 유지한다.
- 생성 후 바로 적용하지 않고 투명도·잘림·작은 화면 식별성·문자 생성 여부를 검수한다.
- 한 번에 전체 에셋을 생성하지 않고 Batch 단위로 생성→적용→테스트한다.

## 3. 에셋 기술 규격

### 3.1 파일 형식

| 용도 | 형식 | 권장 규격 |
|---|---|---|
| 배경 일러스트 | PNG 또는 WebP | 1080×1920 이상, 세로 9:16 |
| 초상화 | PNG/WebP | 대형 512×640, 목록 256×320 |
| UI 프레임 | PNG | 9-slice 모서리 보존 |
| 아이콘 | 투명 PNG | 64×64 또는 96×96 |
| Flame 스프라이트 | 투명 PNG | 128×128 또는 256×256 |
| 애니메이션 | 동일 크기 PNG 프레임 | 4~8프레임 |

### 3.2 저장 규칙

```text
assets/images/
  backgrounds/
  ui/
  icons/
  portraits/
  emblems/
  map/
  battle/
  effects/
```

기존 루트의 이미지들은 1차 정리 단계에서 위 폴더로 이동한다. 이동 시 기존 경로를 직접 참조하는 코드를 `AssetRepository` key 참조로 교체한다.

### 3.3 AssetRepository

이미지 경로를 화면 코드에 직접 반복하지 않는다.

```dart
class AssetRepository {
  static const titleBackground = 'assets/images/backgrounds/title.png';
  static const worldMapBackground = 'assets/images/backgrounds/world_map.png';

  static String officerPortrait(String officerId) =>
      'assets/images/portraits/$officerId.png';
}
```

최종 단계에서는 문자열 상수를 데이터팩의 `portraitAsset`, `emblemAsset`, `markerAsset`과 연결한다. 파일이 없는 경우를 대비해 개발용 fallback 에셋을 둔다.

## 4. 단계별 실행 계획

### Stage 0 — 시각 기준 고정 ✅ 1차 완료

목표: 생성 전에 스타일을 고정해 에셋 간 불일치를 막는다.

생성 기준:

- 팔레트: charcoal, deep teal, olive, umber, antique gold, parchment
- 재질: aged parchment, dark wood, bronze edge, hand-painted terrain
- 조명: 좌상단 또는 상단 중앙의 따뜻한 광원
- 카메라: UI 배경은 세로, 지도는 탑다운, 초상화는 머리·어깨 클로즈업
- 금지: 현대 아이콘, 네온, 실사 사진, 원작과 동일한 인물·문양·문구

구현:

- `ASSET_GAP_ANALYSIS.md`의 P0 목록을 제작 티켓으로 분리한다.
- 색상 토큰과 패널 토큰을 `ui/theme_tokens.dart`로 이동한다.
- 390×844 기준 캡처용 테스트 화면을 만든다.

완료 기준:

- 모든 생성 프롬프트에 공통 스타일 블록을 사용한다.
- P0와 P1의 경계가 확정된다.

### Stage 1 — 공통 UI 크롬 ✅ 1차 완료

목표: 참고 이미지와 가장 큰 차이인 “기본 Material 위젯 느낌”을 제거한다.

imagegen 생성:

- 창 프레임: normal, highlighted, warning, disabled
- 버튼 프레임: normal, pressed, selected, disabled
- 탭 프레임 6종
- 섹션 제목판·금속 구분선·확인/취소 도장
- 자원·능력치·상태 아이콘 세트

구현:

- `NineSlicePanel` 위젯 생성
- `AssetButton` 위젯 생성
- `AssetTabBar` 위젯 생성
- `AssetIcon` 위젯 생성
- Home, Dialog, ProvincePanel, ActionBar가 공통 위젯을 사용하도록 교체

완료 기준:

- P0 화면에서 임시 `FilledButton`, `Card`, `Icons.*` 사용을 최소화한다.
- 버튼 상태가 실제 `enabled`, `selected`, `pressed`에 따라 바뀐다.
- 화면 폭이 변해도 프레임 모서리가 늘어나지 않는다.

### Stage 2 — 세계관 정체성 ✅ 1차 완료

목표: 군주 선택과 세계 지도가 참고 화면처럼 한눈에 구분되게 한다.

imagegen 생성:

- 군주 3명 대형 초상화
- 주요 장수 12명 초상화
- 세력 문장 3종
- 시나리오 카드 썸네일 4종
- 도시·성·항구·산성·관문 마커
- 플레이어/중립/적군/선택/안개 지도 마커

구현:

- `OfficerState.id`와 초상화 key를 1:1 매핑
- `ForceState.id`와 문장 key를 1:1 매핑
- 지도 노드의 원형 텍스트를 도시 마커와 깃발로 교체
- 시나리오 카드에 썸네일과 난이도 배지 표시
- 군주 선택 카드에 대형 초상화·세력 규모·능력치 아이콘 표시

완료 기준:

- 20장수가 같은 3개 이미지로 반복되지 않는다.
- 6개 지역의 마커와 3개 세력의 문장이 구분된다.
- 정보가 가려진 적 지역은 안개 오버레이와 `????`를 함께 표시한다.

### Stage 3 — 지역·내정·인사·군사 UI ✅ 1차 완료

목표: 참고 이미지의 중간 행에 해당하는 명령 화면을 완성한다.

imagegen 생성:

- 지역 대표 일러스트 6종
- 개발·치수·징세·시혜·군량 거래 아이콘
- 탐색 장면 2종과 발견 결과 배지
- 등용·관계·성공률·포상 아이콘
- 병력 이동·보급·출병 준비 아이콘
- 부대 카드와 총대장 프레임

구현:

- 지역 상세 상단에 지역 일러스트와 자원 아이콘 배치
- `_ActionBar`를 내정·인사·군사·외교·첩보 그룹으로 시각 분리
- 명령 미리보기 Dialog에 아이콘·비용·예상 결과·위험 표시
- 탐색·등용·포상·이동 결과에 결과 배지와 장수 초상화 표시
- 출병 준비 카드에 부대별 깃발·장수·병력·군량 표시

완료 기준:

- 사용자가 아이콘만 보고 명령 범주를 구분할 수 있다.
- 명령 결과가 숫자 변화뿐 아니라 이미지 배지로 피드백된다.
- 세로 화면에서 명령 패널이 하단 조작 영역을 침범하지 않는다.

### Stage 4 — 전투판 아트와 Flame 연결 ✅ 1차 완료

목표: 전투 화면의 코드 도형을 데이터 기반 이미지 컴포넌트로 교체한다.

imagegen 생성:

- 평원·숲·산·강·성채 타일 아틀라스
- 공격군·방어군·병과별 부대 스프라이트
- 세력 깃발과 총대장 깃발
- 선택 칸·이동 가능 칸·공격 범위·협공 범위 오버레이
- 보급 마차·군량·사기 아이콘

구현:

- `TerrainSpriteComponent` 생성
- `BattleUnitComponent`를 `SpriteComponent` 기반으로 변경
- `BattleSelectionComponent`와 `BattleRangeComponent` 분리
- `BattleState`의 terrain, owner, morale, burning에 따라 asset key 선택
- 색상 필터만으로 적군을 표현하지 않고 세력별 깃발·스프라이트를 사용

완료 기준:

- Flame에서 `CircleComponent`로 부대를 표현하지 않는다.
- 지형별 이동·방어 규칙과 지형 이미지가 일치한다.
- 선택·이동·공격 가능 상태가 이미지 오버레이로 구분된다.

### Stage 5 — 전투 연출과 결과 ✅ 1차 완료

목표: 참고 이미지의 화공·피해 숫자·전투 결과처럼 행동의 결과를 즉시 읽게 한다.

imagegen 생성:

- 화공 4프레임
- 돌격 3프레임
- 일반 공격·피격·사망·퇴각 이펙트
- 피해 숫자 배지와 사기 저하 표시
- 승리·패배·점령·전사·포로 결과 플레이트

구현:

- `BattleEvent`에 `fire`, `charge`, `hit`, `retreat`, `capture`, `victory`를 추가
- `BattleEffectComponent`가 이벤트를 받아 SpriteAnimation 재생
- 이펙트 종료 후 자동 제거
- 결과 Dialog에 결과 플레이트·자원 아이콘·장수 초상화·포로 프레임 표시
- AI 전투 관전에도 같은 연출 컴포넌트를 재사용

완료 기준:

- 화공·돌격·일반 공격이 화면에서 서로 다른 연출로 보인다.
- 피해 수치와 사기 변화가 1초 안에 표시된다.
- 전투 결과 화면에서 영토·병력·포로·전리품을 이미지와 숫자로 확인한다.

### Stage 6 — 외교·첩보·월말 이벤트 ✅ 1차 완료

목표: 참고 이미지 하단 행의 시스템 화면을 시각적으로 완성한다.

imagegen 생성:

- 외교 대화 배경과 세력 문장
- 선물 상자·동맹 인장·협박 경고
- 첩자 실루엣·정보 문서·발각 도장
- 풍년·홍수·질병·상인 이벤트 일러스트
- 증감·성공·실패·정보 공개 배지

구현:

- 외교 Dialog에 세력 문장·관계 단계·행동별 아이콘 표시
- 첩보 Dialog에 실행 장수 초상화·대상 초상화·성공률 게이지 표시
- 월말 요약에 이벤트 일러스트와 자원 증감 아이콘 표시
- 이벤트 종류는 `eventAsset` key로 데이터에서 선택

완료 기준:

- 외교와 첩보가 같은 일반 Dialog처럼 보이지 않는다.
- 월말 이벤트 종류가 일러스트만으로도 구분된다.
- 정보 공개·발각·동맹 상태가 아이콘과 텍스트로 함께 표시된다.

### Stage 7 — 전체 시각 QA와 최적화 ✅ 프로토타입 완료

목표: 생성 이미지가 실제 모바일 게임 화면에서 안정적으로 보이는지 확인한다.

검수 기기/크기:

- 390×844 기준
- 작은 iPhone 폭
- 일반 Android 폭
- Pro Max 폭
- Flutter Web 브라우저 폭 360~600

검수 항목:

- 이미지가 흐리거나 잘리지 않는가
- 텍스트가 얼굴·아이콘·중요 지형을 가리지 않는가
- 버튼 상태가 이미지 대비 충분히 읽히는가
- 초상화가 같은 인물로 오인되지 않는가
- Web·iOS·Android에서 asset path가 동일하게 로드되는가
- 초기 로딩 시 이미지가 늦게 나타나도 레이아웃이 흔들리지 않는가
- 메모리 사용량과 Web bundle 크기가 허용 범위인가

구현:

- `AssetPrecache`로 시작 화면·지도·전투 핵심 자산을 미리 로드
- `Image.errorBuilder`와 Flame asset fallback 추가
- 화면별 golden screenshot 또는 수동 캡처 체크리스트 작성
- 큰 원본은 WebP/해상도 변형으로 최적화

완료 기준:

- 17개 화면의 체크리스트가 모두 통과한다.
- `flutter analyze`, unit test, `flutter build web`이 통과한다.
- iOS/Android asset bundle에서 모든 P0 자산이 로드된다.
- 시각 QA 후에만 다음 Batch를 시작한다.

## 5. 배치별 일정과 산출물

| 배치 | 범위 | 주요 산출물 | 완료 게이트 |
|---|---|---|---|
| A | 공통 UI 크롬 | 프레임·버튼·탭·자원 아이콘 | 시작·지도·지역 화면의 임시 Material UI 제거 |
| B | 세계관 정체성 | 초상화·문장·마커·썸네일 | 군주·지역·세력이 이미지로 구분됨 |
| C | 전략 명령 | 내정·인사·군사·출병 자산 | 명령 미리보기와 결과가 시각적으로 완성됨 |
| D | 전투 아트 | 타일·부대·깃발·선택 오버레이 | Flame 코드 도형을 이미지 컴포넌트로 교체 |
| E | 전투 연출 | 화공·돌격·피격·결과 플레이트 | 전투 행동별 연출과 결과 처리가 연결됨 |
| F | 시스템 피드백 | 외교·첩보·이벤트 에셋 | 월말·외교·첩보 화면이 독립된 시각 언어를 가짐 |
| G | QA·최적화 | precache·fallback·압축·캡처 | Web/iOS/Android 검증과 배포 완료 |

각 배치는 다음 순서를 지킨다.

```text
프롬프트 확정
→ imagegen 생성
→ 출력 검수
→ assets 폴더 저장
→ manifest/key 등록
→ 화면 연결
→ 테스트·시각 검수
→ 문서 체크
→ commit/push
```

## 6. 하지 않을 것

- 생성 이미지에 게임 수치나 한국어 버튼 문구를 직접 넣지 않는다.
- 한 장의 합성 UI 이미지를 전체 화면 위에 깔고 그 위에 클릭 영역만 얹지 않는다.
- 이미지가 GameState를 직접 변경하게 하지 않는다.
- 원작 스크린샷을 crop하거나 색상만 바꿔 사용하지 않는다.
- 모든 장수를 생성하기 전에 프레임·데이터 매핑 규칙을 먼저 확정하지 않는다.
- 전투 이펙트를 BattleEngine 안에서 직접 그리지 않는다.

## 7. 최종 완료 정의

다음 조건을 모두 만족하면 이미지 에셋 1차 완성으로 판단한다.

- [x] P0 에셋이 생성되고 `assets`에 저장됐다.
- [x] P0 에셋이 `AssetRepository` key와 연결됐다.
- [x] 참고 화면의 주요 화면군에 전용 이미지 요소가 최소 1개 이상 있다.
- [x] 장수·세력·지역 이미지가 데이터 ID/fallback 규칙과 연결된다.
- [x] 전투 지형·부대·이펙트가 Flame component로 연결됐다.
- [x] 공통 버튼·패널의 활성/비활성 상태가 구분된다.
- [x] 390×844 대응 구조와 Web 빌드가 확인됐다.
- [x] `flutter test`, `flutter analyze`, `flutter build web --release`가 통과한다.
- [ ] GitHub Pages에서 최종 배포 URL의 이미지 로딩을 확인한다.

## 8. 1차 구현 완료 기록

2026-08-21 기준 Stage 0~7 프로토타입 패스를 완료했다.

- `AssetRepository`, `StrategyTokens`, `AssetPanel`, `AssetButton`, `AssetPrecache` 추가
- imagegen 생성 에셋을 배경·패널·초상화·명령 스트립·세력 문장·이벤트·전투 지형·전투 효과·부대 토큰에 연결
- 시나리오 선택, 월말 보고, `_ActionBar`, Flame 전투판에서 실제 렌더링 확인
- 초상화와 배경에 `errorBuilder`, Flame에는 이미지 기반 지형·효과·부대 렌더링 추가
- `flutter analyze`, `flutter test`, `flutter build web --release` 통과

이번 완료는 게임 플레이가 가능한 1차 시각 프로토타입이다. 전체 출시 품질을 위해서는 이후 배치에서 장수별 초상화 20종, 지역별 일러스트 6종, 세부 상태별 버튼/탭 프레임, 실제 애니메이션 프레임 아틀라스를 확장한다.

## 9. 다음 실행 단계

다음 구현은 출시 품질 확장 배치다. 장수별 초상화·지역별 일러스트·상태별 버튼 프레임·실제 전투 애니메이션 아틀라스를 추가하고, GitHub Pages에서 최종 URL을 확인한다.

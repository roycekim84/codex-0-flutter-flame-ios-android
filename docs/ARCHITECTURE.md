# Architecture

`GameState`는 순수 도메인 상태, `CommandEngine`은 유형화된 명령의 검증·결과 계산을 담당한다. Flutter UI는 선택 상태를 관리하고 명령을 dispatch할 뿐 상태를 직접 수정하지 않는다.

```text
Flutter UI → GameCommand → CommandEngine → GameState → GameEvent/Report → Flutter UI
Battle UI / Flame → BattleCommand → BattleEngine → BattleState → BattleResult

AI는 `AiEngine`에서 행동을 선택하고 `GameEngine`이 선택 결과를 GameState와 로그에 적용한다. AI 판단과 상태 변경을 분리해 이후 성격별 우선순위를 확장한다. AI 군사 행동도 `BattleEngine`을 호출하며, Flame은 플레이어 전투와 동일하게 전투 화면을 렌더링할 수 있는 경계를 유지한다.
```

Flame은 전술 전투의 렌더러/입력 계층으로만 사용한다. 지역·세력·장수·밸런스·이벤트 데이터는 JSON repository로 교체한다. 피해·이동·화공·포로 상태를 Flame Component가 직접 결정하지 않는다.

화면 모듈은 `home`, `scenario`, `ruler_select`, `world_map`, `province`, `domestic`, `personnel`, `military`, `battle`, `diplomacy`, `espionage`, `result`로 분리한다. 지역 상세와 명령 미리보기는 공통 읽기 모델을 사용하고, 화면별로 GameState를 직접 편집하지 않는다.

# Architecture

`GameState`는 순수 도메인 상태, `CommandEngine`은 유형화된 명령의 검증·결과 계산을 담당한다. Flutter UI는 선택 상태를 관리하고 명령을 dispatch할 뿐 상태를 직접 수정하지 않는다.

```text
Flutter UI → GameCommand → CommandEngine → GameState → GameEvent/Report → Flutter UI
Battle UI / Flame → BattleCommand → BattleEngine → BattleState → BattleResult
```

Flame은 전술 전투의 렌더러/입력 계층으로만 사용한다. 지역·세력·장수·밸런스·이벤트 데이터는 JSON repository로 교체한다. 피해·이동·화공·포로 상태를 Flame Component가 직접 결정하지 않는다.

화면 모듈은 `home`, `scenario`, `ruler_select`, `world_map`, `province`, `domestic`, `personnel`, `military`, `battle`, `diplomacy`, `espionage`, `result`로 분리한다. 지역 상세와 명령 미리보기는 공통 읽기 모델을 사용하고, 화면별로 GameState를 직접 편집하지 않는다.

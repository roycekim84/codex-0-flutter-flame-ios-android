# Architecture

`GameState`는 순수 도메인 상태, `GameEngine`은 명령의 결과를 계산한다. Flutter UI는 선택 상태를 관리하고 엔진의 공개 메서드로만 변경을 요청한다.

```text
Flutter UI → GameEngine command → GameState → ChangeNotifier → Flutter UI
Battle UI → BattleCommand → BattleEngine → BattleState
```

Flame은 전술 전투의 렌더러/입력 계층으로만 사용한다. 지역·세력·장수 데이터는 `DemoScenario`와 향후 JSON repository로 교체한다.

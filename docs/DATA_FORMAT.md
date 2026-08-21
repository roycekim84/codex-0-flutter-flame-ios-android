# Data format

시나리오는 다음 최상위 필드를 가진다.

```json
{"id":"generic_prototype","year":193,"month":1,"playerForceId":"force_green","randomSeed":42,"forces":[],"provinces":[],"officers":[]}
```

`Province`는 `id`, `name`, `ownerForceId`, `adjacentProvinceIds`, `land`, `publicLoyalty`, `soldiers`, `officerIds`를 가진다. `Officer`는 `id`, `name`, `forceId`, `provinceId`, `war`, `intelligence`, `charisma`, `loyalty`, `status`를 가진다. 능력치는 1~100, 충성도는 0~100으로 검증한다.

# Data format

시나리오는 다음 최상위 필드를 가진다.

```json
{"id":"generic_prototype","year":193,"month":1,"playerForceId":"force_green","randomSeed":42,"forces":[],"provinces":[],"officers":[]}
```

`generic_prototype`은 회귀 테스트용 가상 시나리오이며, 한국 삼국시대 데이터팩은
`scenario_korea_642`를 사용한다. 두 시나리오는 동일한 엔진과 저장 구조를 공유한다.

시나리오 JSON은 `ScenarioRepository`를 통해 읽는다. 로더는 GameState에 전달하기
전에 세력·지역·장수 ID, 소유권, 인접 관계, 역사 인물 메타데이터와 능력치 범위를
검증한다. 따라서 이후 인물 100명 데이터팩도 엔진 코드 수정 없이 JSON으로 교체할
수 있다.

`Force`는 `id`, `name`, `rulerId`, `provinceIds`, `officerIds`, `mapColorValue`,
`bannerIndex`, `bannerAssetId`, `capitalProvinceId`를 가진다. `Province`는 `id`,
`name`, `ownerForceId`, `adjacentProvinceIds`, `land`, `publicLoyalty`, `soldiers`,
`officerIds`, `settlementType`를 가진다. `Officer`는 `id`, `name`, `forceId`,
`provinceId`, `war`, `intelligence`, `charisma`, `loyalty`, `status`,
`historicalStatus`, `portraitAssetId`를 가진다. 능력치는 1~100, 충성도는 0~100으로
검증한다. `bannerAssetId`와 `portraitAssetId`는 실제 에셋 경로가 아니라 데이터 식별자이며,
AssetRepository가 플랫폼별 경로를 결정한다.

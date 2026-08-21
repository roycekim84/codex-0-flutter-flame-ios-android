enum TerrainType { plain, forest, mountain, river, fort }

extension TerrainTypeRules on TerrainType {
  double get attackModifier => switch (this) {
    TerrainType.plain => 1.0,
    TerrainType.forest => .85,
    TerrainType.mountain => .75,
    TerrainType.river => .65,
    TerrainType.fort => .70,
  };
  double get fireModifier => switch (this) {
    TerrainType.plain => 1.0,
    TerrainType.forest => 1.35,
    TerrainType.mountain => .7,
    TerrainType.river => .45,
    TerrainType.fort => .8,
  };
}

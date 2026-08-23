class AssetRepository {
  const AssetRepository._();

  static const titleBackground = 'assets/images/title_background.png';
  static const titleCrest = 'assets/images/title_crest.png';
  static const scenarioThumbnailStrip =
      'assets/images/scenario_thumbnail_strip.png';
  static const worldMapBackground = 'assets/images/world_map_background.png';
  static const worldMapRegions = 'assets/images/world_map_regions.png';
  static const fortressMarker = 'assets/images/fortress_marker.png';
  static const fortressLarge = 'assets/images/fortress_large.png';
  static const fortressMedium = 'assets/images/fortress_medium.png';
  static const fortressSmall = 'assets/images/fortress_small.png';
  static const mapCommandIcons = 'assets/images/map_command_icons.png';

  static String commandIcon(int index) =>
      'assets/images/command_icon_${index.clamp(0, 6)}.png';
  static const battleBackground = 'assets/images/battle_background.png';
  static const panelTexture = 'assets/images/panel_texture.png';
  static const commandIconStrip = 'assets/images/command_icon_strip.png';
  static const battleUnitToken = 'assets/images/battle_unit_token.png';
  static const battleUnitTokenAlpha =
      'assets/images/battle_unit_token_alpha.png';
  static const factionEmblemStrip = 'assets/images/faction_emblem_strip.png';
  static const forceBannerStrip = 'assets/images/force_banner_strip.png';
  static const battleTerrainOverlay =
      'assets/images/battle_terrain_overlay.png';
  static const battleEffectsStrip = 'assets/images/battle_effects_strip.png';
  static const eventArtStrip = 'assets/images/event_art_strip.png';

  static String officerPortrait(String officerId) {
    const assignments = <String, String>{
      'o_red_01': 'assets/images/officer_portrait_warrior.png',
      'o_red_02': 'assets/images/officer_portrait_strategist.png',
      'o_red_03': 'assets/images/officer_portrait_governor.png',
      'o_blue_01': 'assets/images/officer_portrait_strategist.png',
      'o_blue_02': 'assets/images/officer_portrait_warrior.png',
      'o_blue_03': 'assets/images/officer_portrait_governor.png',
    };
    return assignments[officerId] ??
        switch (officerId.codeUnits.fold<int>(0, (sum, code) => sum + code) %
            3) {
          0 => 'assets/images/officer_portrait_warrior.png',
          1 => 'assets/images/officer_portrait_strategist.png',
          _ => 'assets/images/officer_portrait_governor.png',
        };
  }
}

import 'package:flutter/material.dart';

import 'asset_repository.dart';

abstract final class AssetPrecache {
  static const critical = <String>[
    AssetRepository.titleBackground,
    AssetRepository.titleCrest,
    AssetRepository.scenarioThumbnailStrip,
    AssetRepository.worldMapBackground,
    AssetRepository.battleBackground,
    AssetRepository.battleFieldBackground,
    AssetRepository.battleCavalryTokenAlpha,
    AssetRepository.battleArcherTokenAlpha,
    AssetRepository.panelTexture,
    AssetRepository.fortressLarge,
    AssetRepository.fortressMedium,
    AssetRepository.fortressSmall,
    'assets/images/command_icon_0.png',
    'assets/images/command_icon_1.png',
    'assets/images/command_icon_2.png',
    'assets/images/command_icon_3.png',
    'assets/images/command_icon_4.png',
    'assets/images/command_icon_5.png',
    'assets/images/command_icon_6.png',
    AssetRepository.commandIconStrip,
    AssetRepository.factionEmblemStrip,
    AssetRepository.eventArtStrip,
    ...AssetRepository.battleRendererAssets,
  ];

  static void schedule(BuildContext context) {
    for (final path in critical) {
      precacheImage(AssetImage(path), context);
    }
  }
}

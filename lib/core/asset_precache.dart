import 'package:flutter/material.dart';

import 'asset_repository.dart';

abstract final class AssetPrecache {
  static const critical = <String>[
    AssetRepository.titleBackground,
    AssetRepository.worldMapBackground,
    AssetRepository.battleBackground,
    AssetRepository.panelTexture,
    AssetRepository.commandIconStrip,
    AssetRepository.factionEmblemStrip,
    AssetRepository.eventArtStrip,
  ];

  static void schedule(BuildContext context) {
    for (final path in critical) {
      precacheImage(AssetImage(path), context);
    }
  }
}

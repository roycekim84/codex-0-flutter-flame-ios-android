import 'package:flutter/material.dart';

import '../../core/asset_repository.dart';
import '../theme_tokens.dart';

class AssetPanel extends StatelessWidget {
  const AssetPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.width,
    this.decoration,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? width;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: decoration ?? StrategyTokens.panelDecoration,
      child: child,
    );
  }
}

class AssetButton extends StatelessWidget {
  const AssetButton({
    super.key,
    required this.label,
    this.iconAsset,
    this.iconIndex,
    this.onPressed,
    this.primary = false,
  });

  final String label;
  final String? iconAsset;
  final int? iconIndex;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconAsset != null) ...[
          AssetSlice(
            asset: iconAsset!,
            index: iconIndex ?? 0,
            segments: 4,
            size: 22,
          ),
          const SizedBox(width: 6),
        ],
        Text(label),
      ],
    );
    return primary
        ? FilledButton(onPressed: onPressed, child: content)
        : FilledButton.tonal(onPressed: onPressed, child: content);
  }
}

/// Displays one segment from a generated horizontal strip.
class AssetSlice extends StatelessWidget {
  const AssetSlice({
    super.key,
    required this.asset,
    required this.index,
    required this.segments,
    this.size = 48,
    this.width,
    this.height,
  });

  final String asset;
  final int index;
  final int segments;
  final double size;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final frameWidth = width ?? size;
    final frameHeight = height ?? size;
    final alignment = -1 + (2 * index / (segments - 1));
    return SizedBox(
      width: frameWidth,
      height: frameHeight,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment(alignment, 0),
          maxWidth: frameWidth * segments,
          maxHeight: frameHeight,
          child: Image.asset(
            asset,
            width: frameWidth * segments,
            height: frameHeight,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}

/// Renders a dedicated Korean faction banner when one exists and falls back
/// to the legacy generated strip for generic scenarios.
class FactionBanner extends StatelessWidget {
  const FactionBanner({
    super.key,
    required this.bannerAssetId,
    required this.fallbackIndex,
    required this.segments,
    this.size = 48,
    this.width,
    this.height,
  });

  final String? bannerAssetId;
  final int fallbackIndex;
  final int segments;
  final double size;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final frameWidth = width ?? size;
    final frameHeight = height ?? size;
    final asset = AssetRepository.factionBanner(bannerAssetId);
    if (asset != AssetRepository.forceBannerStrip) {
      return SizedBox(
        width: frameWidth,
        height: frameHeight,
        child: Image.asset(asset, fit: BoxFit.contain),
      );
    }
    return AssetSlice(
      asset: asset,
      index: fallbackIndex,
      segments: segments,
      width: frameWidth,
      height: frameHeight,
    );
  }
}

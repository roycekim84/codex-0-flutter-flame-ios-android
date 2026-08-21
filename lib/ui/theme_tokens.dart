import 'package:flutter/material.dart';

abstract final class StrategyTokens {
  static const background = Color(0xff171612);
  static const panel = Color(0xff29241b);
  static const panelDark = Color(0xff211e18);
  static const bronze = Color(0xffa8844b);
  static const gold = Color(0xfff0d08e);
  static const parchment = Color(0xffe5d2a6);
  static const muted = Color(0xffbba887);
  static const border = Color(0xff5e492d);

  static const panelDecoration = BoxDecoration(
    color: panel,
    border: Border.fromBorderSide(BorderSide(color: border)),
    image: DecorationImage(
      image: AssetImage('assets/images/panel_texture.png'),
      fit: BoxFit.cover,
      opacity: .18,
    ),
  );
}

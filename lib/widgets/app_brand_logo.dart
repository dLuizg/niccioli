import 'package:flutter/material.dart';

class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({super.key, this.width, this.height});

  static const String assetPath = 'assets/branding/niccioli_logo.png';

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Niccioli Viagens e Turismo',
    );
  }
}

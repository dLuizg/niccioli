import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niccioli/screens/login/login_screen.dart';
import 'package:niccioli/theme/app_colors.dart';
import 'package:niccioli/widgets/app_brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loaderController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _navigationTimer = Timer(const Duration(seconds: 3), _goToLogin);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _loaderController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppBrandLogo(width: 280, height: 280),
                const SizedBox(height: 40),
                RotationTransition(
                  turns: _loaderController,
                  child: const _CircularLoader(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularLoader extends StatelessWidget {
  const _CircularLoader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: CustomPaint(painter: _CircularLoaderPainter()),
    );
  }
}

class _CircularLoaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 3.5;
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;

    final basePaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = AppColors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.45,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

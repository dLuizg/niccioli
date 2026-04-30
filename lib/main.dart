import 'package:flutter/material.dart';
import 'package:niccioli/screens/financeiro/financeiro_screen.dart';
import 'package:niccioli/screens/mapa/mapa_screen.dart';
import 'screens/splash_screen/splash_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const NiccioliApp());
}

class NiccioliApp extends StatelessWidget {
  const NiccioliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Niccioli',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: AppColors.orange,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
      ),
      home: const FinanceiroScreen(),
    );
  }
}
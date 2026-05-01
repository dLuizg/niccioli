import 'package:flutter/material.dart';
import 'package:niccioli/screens/mapa/mapa_screen.dart';
import 'package:niccioli/screens/notification/notification_screen.dart';
import 'package:niccioli/screens/perfil/account/account_screen.dart';
import 'package:niccioli/screens/perfil/privacy_and_police/privacy_and_policy_screen.dart';
import 'package:niccioli/screens/perfil/profile_screen.dart';
import 'package:niccioli/screens/perfil/security/security_screen.dart';
import 'package:niccioli/screens/perfil/support/support_screen.dart';
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
      routes: {
        ProfileScreen.accountRoute: (_) => const AccountScreen(),
        ProfileScreen.securityRoute: (_) => const SecurityScreen(),
        ProfileScreen.notificationsRoute: (_) => const NotificacaoTela(),
        ProfileScreen.supportRoute: (_) => const SupportScreen(),
        ProfileScreen.privacyRoute: (_) => const PrivacyAndPolicyScreen(),
      },
      home: const SplashScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:niccioli/screens/IA/chat_screen.dart';
import 'screens/splash_screen/splash_screen.dart';
import 'theme/app_colors.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
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
      home: const ChatScreen(), // <-- troca SplashScreen por ChatScreen
    );
  }
}
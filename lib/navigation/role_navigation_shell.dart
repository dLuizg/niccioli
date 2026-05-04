import 'package:flutter/material.dart';
import '../screens/financeiro/financeiro_screen.dart';
import '../screens/home_aluno/home_aluno.dart';
import '../screens/mapa/mapa_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';

enum AppUserRole { aluno, motorista }

class RoleNavigationShell extends StatefulWidget {
  const RoleNavigationShell({super.key, required this.role});

  final AppUserRole role;

  @override
  State<RoleNavigationShell> createState() => _RoleNavigationShellState();
}

class _RoleNavigationShellState extends State<RoleNavigationShell> {
  int _selectedIndex = 0;

  late List<_NavigationDestinationData> _destinations;

  @override
  void initState() {
    super.initState();
    _destinations = _buildDestinations(widget.role);
  }

  @override
  void didUpdateWidget(covariant RoleNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _selectedIndex = 0;
      _destinations = _buildDestinations(widget.role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _destinations.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  static List<_NavigationDestinationData> _buildDestinations(AppUserRole role) {
    final secondTabLabel = role == AppUserRole.aluno ? 'Contrato' : 'Lista';

    return [
      _NavigationDestinationData(
        screen: role == AppUserRole.aluno
            ? const HomeAluno()
            : const _PlaceholderTabScreen(title: 'Home Motorista'),
      ),
      _NavigationDestinationData(
        screen: _PlaceholderTabScreen(title: secondTabLabel),
      ),
      const _NavigationDestinationData(
        screen: HomeScreen(),
      ),
      const _NavigationDestinationData(
        screen: FinanceiroScreen(),
      ),
      const _NavigationDestinationData(
        screen: _PlaceholderTabScreen(title: 'Perfil'),
      ),
    ];
  }
}

class _PlaceholderTabScreen extends StatelessWidget {
  const _PlaceholderTabScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationDestinationData {
  const _NavigationDestinationData({required this.screen});

  final Widget screen;
}

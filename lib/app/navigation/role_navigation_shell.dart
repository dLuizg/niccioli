import 'package:flutter/material.dart';
import 'package:niccioli/app/models/app_user_profile.dart';
import 'package:niccioli/app/pages/perfil/profile_screen.dart';
import '../pages/contrato_aluno/contrato_aluno.dart';
import '../pages/financeiro/financeiro_screen.dart';
import '../pages/home_aluno/home_aluno.dart';
import '../pages/mapa/mapa_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';

class RoleNavigationShell extends StatefulWidget {
  const RoleNavigationShell({
    super.key,
    required this.role,
    this.initialIndex = 0,
  });

  final AppUserRole role;
  final int initialIndex;

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
    _selectedIndex = _clampIndex(widget.initialIndex);
  }

  @override
  void didUpdateWidget(covariant RoleNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _destinations = _buildDestinations(widget.role);
      _selectedIndex = _clampIndex(widget.initialIndex);
    } else if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex = _clampIndex(widget.initialIndex);
    }
  }

  int _clampIndex(int index) {
    if (index < 0) {
      return 0;
    }
    if (index >= _destinations.length) {
      return _destinations.length - 1;
    }
    return index;
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
        secondItemLabel: widget.role == AppUserRole.aluno
            ? 'Contrato'
            : 'Lista',
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
        screen: role == AppUserRole.aluno
            ? const ContratoAluno()
            : _PlaceholderTabScreen(title: secondTabLabel),
      ),
      const _NavigationDestinationData(screen: HomeScreen()),
      const _NavigationDestinationData(screen: FinanceiroScreen()),
      const _NavigationDestinationData(screen: ProfileScreen()),
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

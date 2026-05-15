import 'package:flutter/material.dart';
import 'package:niccioli/app/models/app_user_profile.dart';
import 'package:niccioli/app/pages/notification/notification_screen.dart';
import 'package:niccioli/app/pages/perfil/account/account_screen.dart';
import 'package:niccioli/app/pages/perfil/privacy_and_police/privacy_and_policy_screen.dart';
import 'package:niccioli/app/pages/perfil/profile_screen.dart';
import 'package:niccioli/app/pages/perfil/security/security_screen.dart';
import 'package:niccioli/app/pages/perfil/support/support_screen.dart';
import '../pages/contrato_aluno/contrato_aluno.dart';
import '../pages/contrato_motorista/contrato_motorista.dart';
import '../pages/financeiro/financeiro_screen.dart';
import '../pages/financeiro/financeiro_motorista_screen.dart';
import '../pages/home_aluno/home_aluno.dart';
import '../pages/home_motorista/home_mototista.dart';
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
  late List<GlobalKey<NavigatorState>> _navigatorKeys;

  @override
  void initState() {
    super.initState();
    _configureDestinations(widget.role);
    _selectedIndex = _clampIndex(widget.initialIndex);
  }

  @override
  void didUpdateWidget(covariant RoleNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _configureDestinations(widget.role);
      _selectedIndex = _clampIndex(widget.initialIndex);
    } else if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex = _clampIndex(widget.initialIndex);
    }
  }

  void _configureDestinations(AppUserRole role) {
    _destinations = _buildDestinations(role);
    _navigatorKeys = List.generate(
      _destinations.length,
      (_) => GlobalKey<NavigatorState>(),
    );
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

  void _handleTabTap(int index) {
    if (index == _selectedIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_destinations.length, _buildTabNavigator),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _handleTabTap,
      ),
    );
  }

  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => _screenForRoute(index, settings.name),
        );
      },
    );
  }

  Widget _screenForRoute(int tabIndex, String? routeName) {
    if (tabIndex == 4) {
      switch (routeName) {
        case ProfileScreen.accountRoute:
          return const AccountScreen();
        case ProfileScreen.securityRoute:
          return const SecurityScreen();
        case ProfileScreen.notificationsRoute:
          return const NotificacaoTela(showProfileNavigation: true);
        case ProfileScreen.supportRoute:
          return const SupportScreen();
        case ProfileScreen.privacyRoute:
          return const PrivacyAndPolicyScreen();
      }
    }

    return _destinations[tabIndex].screen;
  }

  static List<_NavigationDestinationData> _buildDestinations(AppUserRole role) {
    return [
      _NavigationDestinationData(
        screen: role == AppUserRole.aluno
            ? const HomeAluno()
            : const HomeMotorista(),
      ),
      _NavigationDestinationData(
        screen: role == AppUserRole.aluno
            ? const ContratoAluno()
            : const ContratoMotorista(),
      ),
      const _NavigationDestinationData(screen: MapaScreen()),
      _NavigationDestinationData(
        screen: role == AppUserRole.aluno
            ? const FinanceiroScreen()
            : const FinanceiroMotoristaScreen(),
      ),
      const _NavigationDestinationData(screen: ProfileScreen()),
    ];
  }
}

class _NavigationDestinationData {
  const _NavigationDestinationData({required this.screen});

  final Widget screen;
}

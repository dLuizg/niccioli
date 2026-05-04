import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
      bottomNavigationBar: _RoleFooterNavigation(
        selectedIndex: _selectedIndex,
        destinations: _destinations,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  static List<_NavigationDestinationData> _buildDestinations(AppUserRole role) {
    final secondTabLabel = role == AppUserRole.aluno ? 'Contrato' : 'Lista';

    return [
      _NavigationDestinationData(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        screen: role == AppUserRole.aluno
            ? const _PlaceholderTabScreen(title: 'Home Aluno')
            : const _PlaceholderTabScreen(title: 'Home Motorista'),
      ),
      _NavigationDestinationData(
        label: secondTabLabel,
        icon: role == AppUserRole.aluno
            ? Icons.description_outlined
            : Icons.format_list_bulleted_outlined,
        activeIcon: role == AppUserRole.aluno
            ? Icons.description
            : Icons.format_list_bulleted,
        screen: _PlaceholderTabScreen(title: secondTabLabel),
      ),
      const _NavigationDestinationData(
        label: 'Mapa',
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on,
        isPrimaryAction: true,
        screen: _PlaceholderTabScreen(title: 'Mapa'),
      ),
      const _NavigationDestinationData(
        label: 'Financeiro',
        icon: Icons.credit_card_outlined,
        activeIcon: Icons.credit_card,
        screen: _PlaceholderTabScreen(title: 'Financeiro'),
      ),
      const _NavigationDestinationData(
        label: 'Perfil',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        screen: _PlaceholderTabScreen(title: 'Perfil'),
      ),
    ];
  }
}

class _RoleFooterNavigation extends StatelessWidget {
  const _RoleFooterNavigation({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<_NavigationDestinationData> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.navBackground),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 86,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < destinations.length; index++)
                  Expanded(
                    child: destinations[index].isPrimaryAction
                        ? _PrimaryNavigationItem(
                            item: destinations[index],
                            selected: selectedIndex == index,
                            onTap: () => onSelected(index),
                          )
                        : _FooterNavigationItem(
                            item: destinations[index],
                            selected: selectedIndex == index,
                            onTap: () => onSelected(index),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterNavigationItem extends StatelessWidget {
  const _FooterNavigationItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavigationDestinationData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.orange : AppColors.inactiveIcon;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                color: color,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryNavigationItem extends StatelessWidget {
  const _PrimaryNavigationItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavigationDestinationData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 1),
            ),
            child: Icon(
              selected ? item.activeIcon : item.icon,
              color: AppColors.white,
              size: 25,
            ),
          ),
        ),
      ),
    );
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
  const _NavigationDestinationData({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
    this.isPrimaryAction = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
  final bool isPrimaryAction;
}

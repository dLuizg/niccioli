import 'package:flutter/material.dart';

// Menu de navegacao inferior com botao central flutuante.
// Uso: AppBottomNav(selectedIndex: _navIndex, onItemTapped: (i) => setState(() => _navIndex = i))
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  static const _activeColor = Color(0xFFFFA600);
  static const _inactiveColor = Color(0xFF676D75);
  static const _bgColor = Color(0xFF091525);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: 68 + bottomPadding,
          color: _bgColor,
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                index: 0,
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
              ),
              _NavItem(
                icon: Icons.groups_outlined,
                label: 'Contrato',
                index: 1,
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
              ),
              // Espaco reservado para o botao central flutuante.
              const Expanded(child: SizedBox()),
              _NavItem(
                icon: Icons.wallet_outlined,
                label: 'Financeiro',
                index: 3,
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Perfil',
                index: 4,
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
              ),
            ],
          ),
        ),
        // Botao central flutuante (indice 2).
        Positioned(
          top: -30,
          child: GestureDetector(
            onTap: () => onItemTapped(2),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _activeColor,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.language, color: Colors.white, size: 30),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = index == selectedIndex;
    final color = isActive ? const Color(0xFFFFA600) : const Color(0xFF676D75);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

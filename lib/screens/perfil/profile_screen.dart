import 'package:flutter/material.dart';
import 'package:niccioli/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.avatarImage,
  });

  final ImageProvider? avatarImage;

  static const String _userName = 'Luiz Gustavo';
  static const String _profileLabel = 'Aluno - Niccioli';

  static const String accountRoute = '/perfil/conta';
  static const String securityRoute = '/perfil/seguranca';
  static const String notificationsRoute = '/notificacoes';
  static const String supportRoute = '/perfil/suporte';
  static const String privacyRoute = '/perfil/privacidade';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 70, 18, 120),
              child: Column(
                children: [
                  _ProfileAvatar(image: avatarImage),
                  const SizedBox(height: 20),
                  const Text(
                    _userName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _profileLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.64),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 34),
                  _ProfileMenuItem(
                    icon: Icons.account_circle_outlined,
                    label: 'Conta',
                    routeName: accountRoute,
                  ),
                  _ProfileMenuItem(
                    icon: Icons.key_outlined,
                    label: 'Seguranca',
                    routeName: securityRoute,
                  ),
                  _ProfileMenuItem(
                    icon: Icons.notifications_none_outlined,
                    label: 'Notificacao',
                    routeName: notificationsRoute,
                  ),
                  _ProfileMenuItem(
                    icon: Icons.phone_outlined,
                    label: 'Suporte',
                    routeName: supportRoute,
                  ),
                  _ProfileMenuItem(
                    icon: Icons.verified_user_outlined,
                    label: 'Politica e Privacidade',
                    routeName: privacyRoute,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.image});

  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      height: 136,
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.orange,
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFFD6D6D6),
        backgroundImage: image,
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.routeName,
  });

  final IconData icon;
  final String label;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.navBackground,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.of(context).pushNamed(routeName),
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: 13),
                Icon(icon, color: AppColors.white, size: 21),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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

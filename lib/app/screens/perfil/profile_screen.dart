import 'package:flutter/material.dart';
import 'package:niccioli/app/models/app_user_profile.dart';
import 'package:niccioli/app/screens/login/login_screen.dart';
import 'package:niccioli/app/services/auth_service.dart';
import 'package:niccioli/app/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.avatarImage});

  final ImageProvider? avatarImage;

  static const String accountRoute = '/perfil/conta';
  static const String securityRoute = '/perfil/seguranca';
  static const String notificationsRoute = '/notificacoes';
  static const String supportRoute = '/perfil/suporte';
  static const String privacyRoute = '/perfil/privacidade';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<AppUserProfile?> _profileFuture;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService.instance.loadCurrentUserProfile();
  }

  Future<void> _signOut() async {
    if (_isSigningOut) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    await AuthService.instance.signOut();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: FutureBuilder<AppUserProfile?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final profile = snapshot.data;
                final fallbackEmail =
                    AuthService.instance.currentUser?.email ?? 'Usuario';

                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 70, 18, 120),
                  child: Column(
                    children: [
                      _ProfileAvatar(image: widget.avatarImage),
                      const SizedBox(height: 20),
                      Text(
                        profile?.name.isNotEmpty == true
                            ? profile!.name
                            : fallbackEmail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile?.profileLabel ?? 'Perfil - Niccioli',
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
                        routeName: ProfileScreen.accountRoute,
                      ),
                      _ProfileMenuItem(
                        icon: Icons.key_outlined,
                        label: 'Seguranca',
                        routeName: ProfileScreen.securityRoute,
                      ),
                      _ProfileMenuItem(
                        icon: Icons.notifications_none_outlined,
                        label: 'Notificacao',
                        routeName: ProfileScreen.notificationsRoute,
                      ),
                      _ProfileMenuItem(
                        icon: Icons.phone_outlined,
                        label: 'Suporte',
                        routeName: ProfileScreen.supportRoute,
                      ),
                      _ProfileMenuItem(
                        icon: Icons.verified_user_outlined,
                        label: 'Politica e Privacidade',
                        routeName: ProfileScreen.privacyRoute,
                      ),
                      _ProfileActionItem(
                        icon: Icons.logout,
                        label: _isSigningOut ? 'Saindo...' : 'Sair',
                        onTap: _isSigningOut ? null : _signOut,
                      ),
                    ],
                  ),
                );
              },
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
    return _ProfileListItem(
      icon: icon,
      label: label,
      onTap: () => Navigator.of(context).pushNamed(routeName),
    );
  }
}

class _ProfileActionItem extends StatelessWidget {
  const _ProfileActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ProfileListItem(icon: icon, label: label, onTap: onTap);
  }
}

class _ProfileListItem extends StatelessWidget {
  const _ProfileListItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.navBackground,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
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

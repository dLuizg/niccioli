import 'package:flutter/material.dart';
import 'package:niccioli/models/app_user_profile.dart';
import 'package:niccioli/navigation/role_navigation_shell.dart';
import 'package:niccioli/services/auth_service.dart';
import 'package:niccioli/theme/app_colors.dart';
import 'package:niccioli/widgets/app_bottom_nav.dart';

class ProfileDetailScaffold extends StatefulWidget {
  const ProfileDetailScaffold({
    super.key,
    required this.child,
    this.headerLabel,
    this.contentPadding = const EdgeInsets.fromLTRB(18, 18, 18, 18),
  });

  final String? headerLabel;
  final Widget child;
  final EdgeInsets contentPadding;

  @override
  State<ProfileDetailScaffold> createState() => _ProfileDetailScaffoldState();
}

class _ProfileDetailScaffoldState extends State<ProfileDetailScaffold> {
  late final Future<AppUserProfile?> _profileFuture;
  AppUserProfile? _profile;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<AppUserProfile?> _loadProfile() async {
    try {
      final profile = await AuthService.instance.loadCurrentUserProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
        });
      } else {
        _profile = profile;
      }
      return profile;
    } on AuthFailure {
      return null;
    }
  }

  Future<void> _navigateToTab(int index) async {
    if (_isNavigating) {
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    final profile = _profile ?? await _profileFuture;

    if (!mounted) {
      return;
    }

    if (profile == null) {
      setState(() {
        _isNavigating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel carregar seu perfil.')),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            RoleNavigationShell(role: profile.role, initialIndex: index),
      ),
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
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: SingleChildScrollView(
                padding: widget.contentPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileDetailHeader(label: widget.headerLabel),
                    const SizedBox(height: 12),
                    widget.child,
                  ],
                ),
              ),
              bottomNavigationBar: AppBottomNav(
                selectedIndex: 4,
                onItemTapped: _navigateToTab,
                secondItemLabel: _profile?.role == AppUserRole.motorista
                    ? 'Lista'
                    : 'Contrato',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailHeader extends StatelessWidget {
  const _ProfileDetailHeader({required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final title = label;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              }
            },
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
          ),
          if (title != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ] else
            const Spacer(),
        ],
      ),
    );
  }
}

class ProfileDarkTile extends StatelessWidget {
  const ProfileDarkTile({
    super.key,
    required this.leading,
    required this.child,
    this.trailing,
    this.height = 36,
  });

  final Widget leading;
  final Widget child;
  final Widget? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 9),
          Expanded(child: child),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

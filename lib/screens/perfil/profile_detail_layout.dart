import 'package:flutter/material.dart';
import 'package:niccioli/theme/app_colors.dart';
import 'package:niccioli/widgets/app_bottom_nav.dart';

class ProfileDetailScaffold extends StatelessWidget {
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
                padding: contentPadding,
                child: child,
              ),
              bottomNavigationBar: AppBottomNav(
                selectedIndex: 4,
                onItemTapped: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileDetailDate extends StatelessWidget {
  const ProfileDetailDate({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Segunda-feira\n14/04/2026',
      style: TextStyle(
        color: AppColors.white.withValues(alpha: 0.9),
        fontSize: 9,
        height: 1.25,
        fontWeight: FontWeight.w500,
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
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

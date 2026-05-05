import 'package:flutter/material.dart';
import 'package:niccioli/navigation/role_navigation_shell.dart';
import 'package:niccioli/screens/login/cadastro_screen.dart';
import 'package:niccioli/theme/app_colors.dart';
import 'package:niccioli/widgets/app_brand_logo.dart';
import 'package:niccioli/widgets/app_button.dart';
import 'package:niccioli/widgets/app_input_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AuthScaffold(child: _LoginCard());
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AppBrandLogo(width: 270, height: 210),
        const SizedBox(height: 34),
        const AppTextField(hintText: 'Digite seu e-mail...'),
        const SizedBox(height: 16),
        const AppTextField(hintText: 'Digite sua senha...', obscureText: true),
        const SizedBox(height: 34),
        AppFilledButton(
          label: 'Entrar',
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) =>
                    const RoleNavigationShell(role: AppUserRole.aluno),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        AppOutlinedButton(
          label: 'Cadastrar',
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CadastroScreen()));
          },
        ),
        const SizedBox(height: 38),
        Text(
          'Entre com outras plataformas',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          width: 138,
          height: 1,
          color: Colors.white.withValues(alpha: 0.25),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialIcon(icon: Icons.apple),
            SizedBox(width: 16),
            _GoogleBadge(),
          ],
        ),
      ],
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
      ),
      child: Icon(icon, size: 18, color: AppColors.white),
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

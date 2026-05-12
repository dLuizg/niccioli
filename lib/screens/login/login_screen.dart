import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:niccioli/navigation/role_navigation_shell.dart';
import 'package:niccioli/screens/login/cadastro_screen.dart';
import 'package:niccioli/theme/app_colors.dart';
import 'package:niccioli/widgets/app_button.dart';
import 'package:niccioli/widgets/app_input_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AuthScaffold(child: _LoginCard());
  }
}

class _LoginCard extends StatefulWidget {
  const _LoginCard();

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Preencha e-mail e senha.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final uid = credential.user!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final role = doc.data()?['role'] as String? ?? 'aluno';
      final appRole = role == 'motorista'
          ? AppUserRole.motorista
          : AppUserRole.aluno;

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => RoleNavigationShell(role: appRole)),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _erro = switch (e.code) {
          'user-not-found' ||
          'wrong-password' ||
          'invalid-credential' => 'E-mail ou senha incorretos.',
          'invalid-email' => 'E-mail inválido.',
          'too-many-requests' => 'Muitas tentativas. Tente mais tarde.',
          _ => 'Erro ao entrar. Tente novamente.',
        };
      });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _BrandHeader(
          logoHeight: 118,
          logoWidth: 160,
          titleSize: 30,
          subtitleSize: 15,
        ),
        const SizedBox(height: 34),
        AppTextField(
          hintText: 'Digite seu e-mail...',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        AppTextField(
          hintText: 'Digite sua senha...',
          obscureText: true,
          controller: _senhaController,
          textInputAction: TextInputAction.done,
        ),
        if (_erro != null) ...[
          const SizedBox(height: 12),
          Text(
            _erro!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 34),
        AppFilledButton(
          label: _carregando ? 'Entrando...' : 'Entrar',
          onPressed: _carregando ? () {} : _entrar,
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.logoWidth,
    required this.logoHeight,
    required this.titleSize,
    required this.subtitleSize,
  });

  final double logoWidth;
  final double logoHeight;
  final double titleSize;
  final double subtitleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: logoWidth,
          height: logoHeight,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                color: Colors.white.withValues(alpha: 0.9),
                size: logoHeight * 0.28,
              ),
              const SizedBox(height: 8),
              Text(
                'Logo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: logoHeight * 0.12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'NICCIOLI',
          style: TextStyle(
            color: AppColors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Viagens e Turismo',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: subtitleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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

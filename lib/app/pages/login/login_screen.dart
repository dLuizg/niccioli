import 'package:flutter/material.dart';
import 'package:niccioli/app/navigation/role_navigation_shell.dart';
import 'package:niccioli/app/pages/login/cadastro_screen.dart';
import 'package:niccioli/app/services/auth_service.dart';
import 'package:niccioli/app/theme/app_colors.dart';
import 'package:niccioli/app/widgets/app_brand_logo.dart';
import 'package:niccioli/app/widgets/app_button.dart';
import 'package:niccioli/app/widgets/app_input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialError});

  final String? initialError;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialError;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final profile = await AuthService.instance.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RoleNavigationShell(role: profile.role),
        ),
        (_) => false,
      );
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      child: _LoginCard(
        formKey: _formKey,
        emailController: _emailController,
        passwordController: _passwordController,
        isSubmitting: _isSubmitting,
        errorMessage: _errorMessage,
        onSubmit: _submit,
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.onSubmit,
    this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppBrandLogo(width: 270, height: 210),
            const SizedBox(height: 34),
            AppTextField(
              hintText: 'Digite seu e-mail...',
              controller: emailController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            AppTextField(
              hintText: 'Digite sua senha...',
              controller: passwordController,
              enabled: !isSubmitting,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: _validatePassword,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              _AuthErrorMessage(message: errorMessage!),
            ],
            const SizedBox(height: 34),
            AppFilledButton(
              label: isSubmitting ? 'Entrando...' : 'Entrar',
              onPressed: isSubmitting ? null : onSubmit,
            ),
            const SizedBox(height: 14),
            AppOutlinedButton(
              label: 'Cadastrar',
              onPressed: isSubmitting
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CadastroScreen(),
                        ),
                      );
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
        ),
      ),
    );
  }

  static String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Informe seu e-mail.';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Digite um e-mail valido.';
    }
    return null;
  }

  static String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Informe sua senha.';
    }
    return null;
  }
}

class _AuthErrorMessage extends StatelessWidget {
  const _AuthErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFFFFC3B8),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
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

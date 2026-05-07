import 'package:flutter/material.dart';
import 'package:niccioli/models/app_user_profile.dart';
import 'package:niccioli/navigation/role_navigation_shell.dart';
import 'package:niccioli/screens/login/cadastro_view_model.dart';
import 'package:niccioli/services/auth_service.dart';
import 'package:niccioli/theme/app_colors.dart';
import 'package:niccioli/utils/br_value_masks.dart';
import 'package:niccioli/widgets/app_button.dart';
import 'package:niccioli/widgets/app_input_field.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _viewmodel = CadastroViewModel();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _viewmodel.dispose();
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
      final profile = await _viewmodel.createAccount();

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
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _CadastroBrandHeader(),
                              const SizedBox(height: 22),
                              AppDropdownField<AppUserRole>(
                                value: _viewmodel.selectedRole,
                                hintText: 'Selecione se voce e Aluno/Motorista',
                                items: AppUserRole.values,
                                itemLabelBuilder: (role) => role.displayLabel,
                                onChanged: _isSubmitting
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _viewmodel.selectedRole = value;
                                          if (value != AppUserRole.aluno) {
                                            _viewmodel.selectedUniversity =
                                                null;
                                          }
                                        });
                                      },
                              ),
                              if (_viewmodel.isAluno) ...[
                                const SizedBox(height: 12),
                                AppDropdownField<String>(
                                  value: _viewmodel.selectedUniversity,
                                  hintText: 'Selecione sua universidade',
                                  items: const ['UNIFEOB', 'UNIFAE'],
                                  onChanged: _isSubmitting
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _viewmodel.selectedUniversity =
                                                value;
                                          });
                                        },
                                ),
                              ],
                              const SizedBox(height: 14),
                              AppTextField(
                                hintText: 'Nome Completo',
                                controller: _viewmodel.nameController,
                                enabled: !_isSubmitting,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                validator: _validateRequired,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                hintText: 'E-mail',
                                controller: _viewmodel.emailController,
                                enabled: !_isSubmitting,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                hintText: 'CPF ou CNPJ',
                                controller: _viewmodel.documentController,
                                enabled: !_isSubmitting,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  BrValueMasks.cpfCnpjFormatter,
                                ],
                                validator: _validateRequired,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                hintText: 'Digite sua senha',
                                controller: _viewmodel.passwordController,
                                enabled: !_isSubmitting,
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                validator: _validatePassword,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                hintText: 'Repita sua senha...',
                                controller:
                                    _viewmodel.confirmPasswordController,
                                enabled: !_isSubmitting,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                validator: _validatePasswordConfirmation,
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 14),
                                _AuthErrorMessage(message: _errorMessage!),
                              ],
                              const SizedBox(height: 24),
                              AppFilledButton(
                                label: _isSubmitting
                                    ? 'Cadastrando...'
                                    : 'Cadastrar',
                                onPressed: _isSubmitting ? null : _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
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

  static String? _validateRequired(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Campo obrigatorio.';
    }
    return null;
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
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Informe sua senha.';
    }
    if (password.length < 6) {
      return 'Use pelo menos 6 caracteres.';
    }
    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Repita sua senha.';
    }
    if (value != _viewmodel.passwordController.text) {
      return 'As senhas nao conferem.';
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

class _CadastroBrandHeader extends StatelessWidget {
  const _CadastroBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: 24,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 4),
              Text(
                'Logo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'NICCIOLI',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Viagens e Turismo',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

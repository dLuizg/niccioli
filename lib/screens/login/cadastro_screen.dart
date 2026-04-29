import 'package:flutter/material.dart';
import 'package:niccioli/theme/app_colors.dart';
import 'package:niccioli/widgets/app_button.dart';
import 'package:niccioli/widgets/app_input_field.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  String? _perfilSelecionado;
  String? _universidadeSelecionada;

  bool get _isAluno => _perfilSelecionado == 'Aluno';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 10),
                    child: Text(
                      'CADASTRO CPF/PJ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const _CadastroBrandHeader(),
                            const SizedBox(height: 22),
                            AppDropdownField<String>(
                              value: _perfilSelecionado,
                              hintText: 'Selecione se voce e Aluno/Motorista',
                              items: const ['Aluno', 'Motorista'],
                              onChanged: (value) {
                                setState(() {
                                  _perfilSelecionado = value;
                                  if (value != 'Aluno') {
                                    _universidadeSelecionada = null;
                                  }
                                });
                              },
                            ),
                            if (_isAluno) ...[
                              const SizedBox(height: 12),
                              AppDropdownField<String>(
                                value: _universidadeSelecionada,
                                hintText: 'Selecione sua universidade',
                                items: const ['UNIFEOB', 'UNIFAE'],
                                onChanged: (value) {
                                  setState(() {
                                    _universidadeSelecionada = value;
                                  });
                                },
                              ),
                            ],
                            const SizedBox(height: 14),
                            const AppTextField(hintText: 'Nome Completo'),
                            const SizedBox(height: 12),
                            const AppTextField(hintText: 'E-mail'),
                            const SizedBox(height: 12),
                            const AppTextField(hintText: 'CPF ou CNPJ'),
                            const SizedBox(height: 12),
                            const AppTextField(
                              hintText: 'Digite sua senha',
                              obscureText: true,
                            ),
                            const SizedBox(height: 12),
                            const AppTextField(
                              hintText: 'Repita sua senha...',
                              obscureText: true,
                            ),
                            const SizedBox(height: 24),
                            AppFilledButton(
                              label: 'Cadastrar',
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
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

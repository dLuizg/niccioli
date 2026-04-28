import 'package:flutter/material.dart';
import 'package:niccioli/theme/app_colors.dart';
import 'package:niccioli/widgets/app_button.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  String? _perfilSelecionado;
  String? _universidadeSelecionada;

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
                            _AuthDropdownField(
                              value: _perfilSelecionado,
                              hintText: 'Selecione se voce e Aluno/Motorista',
                              items: const ['Aluno', 'Motorista'],
                              onChanged: (value) {
                                setState(() {
                                  _perfilSelecionado = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _AuthDropdownField(
                              value: _universidadeSelecionada,
                              hintText: 'Selecione sua universidade',
                              items: const [
                                'UNIFEOB',
                                'UNIFAE',
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _universidadeSelecionada = value;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            const _AuthTextField(hintText: 'Nome Completo'),
                            const SizedBox(height: 12),
                            const _AuthTextField(hintText: 'E-mail'),
                            const SizedBox(height: 12),
                            const _AuthTextField(hintText: 'CPF ou CNPJ'),
                            const SizedBox(height: 12),
                            const _AuthTextField(
                              hintText: 'Digite sua senha',
                              obscureText: true,
                            ),
                            const SizedBox(height: 12),
                            const _AuthTextField(
                              hintText: 'Repita sua senha...',
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
                            AppFilledButton(
                              label: 'Entrar',
                              onPressed: () {},
                            ),
                            const SizedBox(height: 12),
                            AppOutlinedButton(
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
            ),
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

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.hintText,
    this.obscureText = false,
  });

  final String hintText;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.22),
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _AuthDropdownField extends StatelessWidget {
  const _AuthDropdownField({
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String hintText;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      icon: const Icon(
        Icons.arrow_drop_down,
        color: Colors.black,
      ),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.55),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 14,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

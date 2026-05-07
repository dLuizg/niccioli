import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_toggle_switch.dart';
import '../widgets/app_button.dart';

class BlankScreen extends StatefulWidget {
  const BlankScreen({super.key});

  @override
  State<BlankScreen> createState() => _BlankScreenState();
}

class _BlankScreenState extends State<BlankScreen> {
  // Estado atual do switch — false = desligado, true = ligado
  bool _ativo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notificação',
                    style: TextStyle(color: AppColors.white, fontSize: 16),
                  ),
                  AppToggleSwitch(
                    value: _ativo,
                    onChanged: (v) => setState(() => _ativo = v),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              AppFilledButton(
                label: 'Entrar',
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              AppOutlinedButton(
                label: 'Cadastrar',
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              AppDualOutlinedButton(
                label1: 'CONFIRMAR',
                onPressed1: () {},
                label2: 'NÃO VOU',
                onPressed2: () {},
              ),
              const SizedBox(height: 16),
              AppDualFilledButton(
                label1: 'Entendo,\nquero Cancelar!',
                onPressed1: () {},
                label2: 'Quero Manter o\ntransporte!',
                onPressed2: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

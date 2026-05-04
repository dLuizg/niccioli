import 'package:flutter/material.dart';
import '../widgets/app_toggle_switch.dart';

class ConfiguracoesTela extends StatefulWidget {
  const ConfiguracoesTela({super.key});

  @override
  State<ConfiguracoesTela> createState() => _ConfiguracoesTelaState();
}

class _ConfiguracoesTelaState extends State<ConfiguracoesTela> {
  bool _notificacoes = false;
  bool _modoEscuro = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notificações'),
                AppToggleSwitch(
                  value: _notificacoes,
                  onChanged: (v) => setState(() => _notificacoes = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Modo Escuro'),
                AppToggleSwitch(
                  value: _modoEscuro,
                  onChanged: (v) => setState(() => _modoEscuro = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

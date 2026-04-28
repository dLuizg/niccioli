// widgets/botao_limpar_notificacoes.dart
import 'package:flutter/material.dart';

class BotaoLimparNotificacoes extends StatelessWidget {
  final VoidCallback onConfirmar;

  const BotaoLimparNotificacoes({super.key, required this.onConfirmar});

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Limpar tudo?"),
        content: const Text("Deseja apagar todas as notificações?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Não"),
          ),
          TextButton(
            onPressed: () {
              onConfirmar();
              Navigator.pop(ctx);
            },
            child: const Text("Sim"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_sweep, color: Colors.white),
      onPressed: () => _showDialog(context),
    );
  }
}
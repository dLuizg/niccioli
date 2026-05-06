import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

// Badge outlined que exibe o contador de alunos confirmados na van.
// Uso: ContadorBadge(atual: 4, total: 7)  →  exibe "04/07"
class ContadorBadge extends StatelessWidget {
  // Quantidade de alunos já confirmados na van
  final int atual;
  // Total de alunos esperados na van
  final int total;

  const ContadorBadge({
    super.key,
    required this.atual,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    // Formata com zero à esquerda: 4 → "04", 14 → "14"
    final String texto =
        '${atual.toString().padLeft(2, '0')}/${total.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white, width: 1.5),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

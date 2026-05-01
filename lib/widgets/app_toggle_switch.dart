import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppToggleSwitch extends StatelessWidget {
  const AppToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.labelStyle,
  });

  // true = ligado (laranja), false = desligado (cinza)
  final bool value;

  // Chamado ao tocar — o pai é responsável por atualizar o estado
  final ValueChanged<bool> onChanged;

  // Texto opcional exibido à esquerda do switch
  final String? label;

  // Estilo do texto — ex: TextStyle(color: AppColors.white, fontSize: 16)
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final toggle = GestureDetector(
      // Inverte o valor atual e repassa para o pai via onChanged
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        // Anima a cor de fundo e borda ao mudar de estado
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: 48,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value
              ? AppColors.orange.withValues(alpha: 0.25)
              : AppColors.inactiveIcon.withValues(alpha: 0.2),
          border: Border.all(
            color: value ? AppColors.orange : AppColors.inactiveIcon,
            width: 1.5,
          ),
        ),
        child: AnimatedAlign(
          // Desliza a bolinha da esquerda (off) para a direita (on)
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 18,
            height: 18,
            // Bolinha — cor laranja quando ligado, cinza quando desligado
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AppColors.orange : AppColors.inactiveIcon,
            ),
          ),
        ),
      ),
    );

    // Se não tiver label, retorna só o switch
    if (label == null) return toggle;

    // Com label: Row com texto à esquerda e switch à direita
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label!, style: labelStyle),
        toggle,
      ],
    );
  }
}

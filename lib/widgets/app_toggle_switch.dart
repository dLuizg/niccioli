import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppToggleSwitch extends StatelessWidget {
  const AppToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Inverte o estado ao tocar; o pai decide se faz setState
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        // 220ms é rápido o suficiente para parecer responsivo sem cortar a animação
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AppColors.orange : AppColors.inactiveIcon,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

enum StatusBadgeType {
  vencido,
  aVencer,
  pago,
  cancelado,
  pendente,
  assinado,
  emAberto,
}

extension StatusBadgeTypeStyle on StatusBadgeType {
  String get label {
    switch (this) {
      case StatusBadgeType.emAberto:
        return 'Em Aberto';
      case StatusBadgeType.vencido:
        return 'Vencidos';
      case StatusBadgeType.aVencer:
        return 'A Vencer';
      case StatusBadgeType.pago:
        return 'Pago';
      case StatusBadgeType.cancelado:
        return 'Cancelado';
      case StatusBadgeType.pendente:
        return 'Pendente';
      case StatusBadgeType.assinado:
        return 'Assinado';
    }
  }

  Color get dotColor {
    switch (this) {
      case StatusBadgeType.vencido:
      case StatusBadgeType.cancelado:
        return const Color(0xFFFF2B2B);
      case StatusBadgeType.aVencer:
      case StatusBadgeType.pendente:
        return const Color(0xFFF4C20D);
      case StatusBadgeType.pago:
      case StatusBadgeType.assinado:
        return const Color(0xFF42E21E);
      case StatusBadgeType.emAberto:
        return const Color.fromARGB(255, 255, 255, 255);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case StatusBadgeType.vencido:
      case StatusBadgeType.cancelado:
        return const Color(0xFF6A3242);
      case StatusBadgeType.aVencer:
      case StatusBadgeType.pendente:
        return const Color(0xFFCC960D);
      case StatusBadgeType.pago:
      case StatusBadgeType.assinado:
        return const Color(0xFF1D5E52);
      case StatusBadgeType.emAberto:
        return const Color.fromARGB(255, 0, 174, 255);
    }
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.textStyle,
    this.showDot = true,
  });

  final StatusBadgeType status;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final Color dotColor = status.dotColor;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          if (showDot) const SizedBox(width: 6),
          Text(
            status.label,
            style: (textStyle ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ))
                .copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

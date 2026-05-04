import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class CabecalhoData extends StatelessWidget {
  const CabecalhoData({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime agora = DateTime.now();
    
    // Lógica de formatação
    String dataNumerica = DateFormat("dd/MM/yyyy", "pt_BR").format(agora);
    String rawDia = DateFormat("EEEE", "pt_BR").format(agora);
    String diaSemana = rawDia[0].toUpperCase() + rawDia.substring(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dataNumerica,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          diaSemana,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  
  final String string;
  final Color cor;

  const StatusBadge({super.key, required this.string, required this.cor});

  @override
  Widget build(BuildContext context) {
return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        //COR DO FUNDO DA BADGE
        color: cor.withValues(alpha: 0.15), 
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
        //A BOLINHA LATERAL DA BADGE
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
          //TEXTO DA BADGE
            string,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
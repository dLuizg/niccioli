import 'package:flutter/material.dart';
import 'package:niccioli/screens/perfil/profile_detail_layout.dart';
import 'package:niccioli/theme/app_colors.dart';

class PrivacyAndPolicyScreen extends StatelessWidget {
  const PrivacyAndPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileDetailScaffold(
      headerLabel: 'POLITICA DE PRIVACIDADE',
      contentPadding: EdgeInsets.fromLTRB(18, 18, 18, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [SizedBox(height: 18), _PrivacyCard()],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  static const String _policyText =
      'Esta Politica de Privacidade descreve, de forma provisoria como as informacoes dos usuarios poderao ser coletadas, utilizadas e protegidas no aplicativo de gerenciamento de uso de vans.\n'
      'Durante esta fase de desenvolvimento, o aplicativo podera coletar dados basicos fornecidos pelo usuario, como nome, informacoes de contato e o registro de uso relacionados ao agendamento e utilizacao da van.\n'
      'Esses dados tem como objetivo principal permitir o funcionamento adequado do sistema, incluindo organizacao de horarios, identificacao de usuarios e melhoria da experiencia.\n'
      'As informacoes coletadas nao serao compartilhadas com terceiros, exceto quando necessario para o funcionamento do servico ou mediante obrigacao legal. Medidas razoaveis de seguranca serao adotadas para proteger os dados contra acesso nao autorizado, alteracao ou divulgacao indevida.\n'
      'Este texto e apenas um placeholder e podera ser alterado, atualizado ou substituido conforme novas funcionalidades forem implementadas.';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Politica de Privacidade',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Text(
            _policyText,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14,
              height: 0.92,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

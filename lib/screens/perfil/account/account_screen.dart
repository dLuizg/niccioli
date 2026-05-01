import 'package:flutter/material.dart';
import 'package:niccioli/screens/perfil/profile_detail_layout.dart';
import 'package:niccioli/theme/app_colors.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileDetailScaffold(
      headerLabel: 'CONTA Aluno',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileDetailDate(),
          SizedBox(height: 26),
          Center(
            child: Text(
              'Configuracoes da Conta',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: 28),
          Center(child: _AccountAvatar()),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Alterar foto do perfil',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 18),
          _AccountInfoTile(
            icon: Icons.account_circle_outlined,
            label: 'Nome: Luiz Gustavo',
          ),
          _AccountInfoTile(
            icon: Icons.mail_outline,
            label: 'E-mail: luiz.gustavo@email.com',
          ),
          _AccountInfoTile(
            icon: Icons.phone_outlined,
            label: 'Telefone: (19) 99999-9999',
          ),
          _AccountInfoTile(
            icon: Icons.map_outlined,
            label: 'Endereco: Rua das Palmeiras, 1961',
          ),
          _AccountInfoTile(
            icon: Icons.map_outlined,
            label: 'Ponto padrao: Rua Padrao, 980',
          ),
          _AccountInfoTile(
            icon: Icons.business_outlined,
            label: 'Instituicao: UNIFEOB',
          ),
          ProfileDarkTile(
            leading: Icon(Icons.add, color: AppColors.white, size: 18),
            height: 34,
            child: Text(
              'Cadastrar novo ponto alternativo',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.orange,
        shape: BoxShape.circle,
      ),
      child: const CircleAvatar(backgroundColor: Color(0xFFD6D6D6)),
    );
  }
}

class _AccountInfoTile extends StatelessWidget {
  const _AccountInfoTile({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ProfileDarkTile(
      leading: Icon(icon, color: AppColors.white, size: 16),
      trailing: const Icon(Icons.edit_square, color: AppColors.white, size: 15),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

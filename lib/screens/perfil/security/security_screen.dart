import 'package:flutter/material.dart';
import 'package:niccioli/screens/perfil/profile_detail_layout.dart';
import 'package:niccioli/theme/app_colors.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileDetailScaffold(
      headerLabel: 'SEGURANCA',
      contentPadding: EdgeInsets.fromLTRB(18, 18, 18, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileDetailDate(),
          SizedBox(height: 38),
          Text(
            'Configuracoes de Seguranca',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 72),
          _PasswordTile(hintText: 'Digite a senha atual...'),
          _PasswordTile(hintText: 'Digite a nova senha...'),
          _PasswordTile(hintText: 'Confirme a nova senha...'),
          SizedBox(height: 42),
          Center(child: _ConfirmButton()),
          SizedBox(height: 46),
          ProfileDarkTile(
            leading: Icon(Icons.fingerprint, color: AppColors.white, size: 18),
            height: 42,
            child: Text(
              'Cadastrar biometria',
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

class _PasswordTile extends StatelessWidget {
  const _PasswordTile({required this.hintText});

  final String hintText;

  @override
  Widget build(BuildContext context) {
    return ProfileDarkTile(
      leading: Icon(
        Icons.key_outlined,
        color: AppColors.white.withValues(alpha: 0.72),
        size: 17,
      ),
      height: 45,
      child: Text(
        hintText,
        style: TextStyle(
          color: AppColors.white.withValues(alpha: 0.45),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 58,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.orange, width: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'CONFIRMAR',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

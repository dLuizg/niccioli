import 'package:flutter/material.dart';
import 'package:niccioli/screens/perfil/profile_detail_layout.dart';
import 'package:niccioli/theme/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileDetailScaffold(
      headerLabel: 'SUPORTE',
      contentPadding: EdgeInsets.fromLTRB(18, 18, 18, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 58),
          _SupportText(
            'Para solicitar ajuda relacionada ao aplicativo, entre em contato pelo seguinte telefone:',
          ),
          SizedBox(height: 18),
          _SupportContactTile(phone: '0800 000 0000'),
          SizedBox(height: 46),
          _SupportText(
            'Para contatar o motorista, utilize o seguinte telefone:',
          ),
          SizedBox(height: 18),
          _SupportContactTile(phone: '(19) 99999-8989'),
          SizedBox(height: 42),
          Center(
            child: Text(
              'Esta algum problema?',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 14),
          _ComplaintButton(),
        ],
      ),
    );
  }
}

class _SupportText extends StatelessWidget {
  const _SupportText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          height: 1.1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SupportContactTile extends StatelessWidget {
  const _SupportContactTile({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, color: AppColors.white, size: 17),
          Expanded(
            child: Text(
              phone,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(
            Icons.chat_bubble_outline,
            color: AppColors.white,
            size: 17,
          ),
        ],
      ),
    );
  }
}

class _ComplaintButton extends StatelessWidget {
  const _ComplaintButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navBackground,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: const Text(
          'RECLAME AQUI',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

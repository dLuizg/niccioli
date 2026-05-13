import 'package:flutter/material.dart';
import 'package:niccioli/app/models/contract.dart';
import 'package:niccioli/app/services/contract_service.dart';
import 'package:niccioli/app/theme/app_colors.dart';
import 'package:niccioli/app/views/widgets/status_badge.dart';
import 'package:niccioli/app/widgets/app_button.dart';
import 'package:url_launcher/url_launcher.dart';

class ContratoDetailScreen extends StatefulWidget {
  const ContratoDetailScreen({
    super.key,
    required this.transportId,
    required this.studentId,
    required this.studentName,
    required this.driverUid,
    required this.contract,
  });

  final String transportId;
  final String studentId;
  final String studentName;
  final String driverUid;
  final Contract contract;

  @override
  State<ContratoDetailScreen> createState() => _ContratoDetailScreenState();
}

class _ContratoDetailScreenState extends State<ContratoDetailScreen> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.contract;
    final isCancelled = c.status == ContractStatus.cancelled;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Text(
                c.fileName,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusRow(c),
              const SizedBox(height: 20),
              _buildCardDados(c),
              const SizedBox(height: 16),
              _buildCardDocumentos(c),
              if (!isCancelled) ...[
                const SizedBox(height: 24),
                AppOutlinedButton(
                  label: _isCancelling ? 'Cancelando...' : 'Cancelar Contrato',
                  onPressed: _isCancelling ? null : _confirmCancel,
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
        ),
        _buildSino(),
      ],
    );
  }

  Widget _buildStatusRow(Contract c) {
    return Row(
      children: [
        StatusBadge(
          status: _toBadgeType(c.status),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'Vigência ${_formatDate(c.startDate)} — ${_formatDate(c.endDate)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardDados(Contract c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('DADOS DO CONTRATO'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDado('ALUNO', widget.studentName)),
              Expanded(
                child: _buildDado(
                  'PERÍODO',
                  '${_formatDate(c.startDate)} — ${_formatDate(c.endDate)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildDado('INÍCIO', _formatDate(c.startDate))),
              Expanded(child: _buildDado('FIM', _formatDate(c.endDate))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDado(
                  'MENSALIDADE',
                  'R\$ ${c.monthlyValue.toStringAsFixed(2).replaceAll('.', ',')}',
                ),
              ),
              Expanded(child: _buildDado('VENCIMENTO', 'Dia ${c.paymentDay}')),
            ],
          ),
          if (c.observations != null && c.observations!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildDado('OBSERVAÇÕES', c.observations!),
          ],
        ],
      ),
    );
  }

  Widget _buildCardDocumentos(Contract c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('DOCUMENTOS'),
          const SizedBox(height: 16),
          AppOutlinedButton(
            label: 'Baixar contrato original',
            onPressed: () => _launchUrl(c.fileUrl),
          ),
          if (c.signedFileUrl != null) ...[
            const SizedBox(height: 12),
            AppOutlinedButton(
              label: 'Ver contrato assinado',
              onPressed: () => _launchUrl(c.signedFileUrl!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDado(String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String texto) {
    return Text(
      texto,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o arquivo.'),
            backgroundColor: Color(0xFF6A3242),
          ),
        );
      }
    }
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F3C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Cancelar contrato',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tem certeza que deseja cancelar "${widget.contract.fileName}"? Esta ação não pode ser desfeita.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar', style: TextStyle(color: AppColors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cancelar contrato',
              style: TextStyle(color: Color(0xFFFF2B2B)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await ContractService.instance.cancelContract(
        widget.transportId,
        widget.studentId,
        widget.contract.id,
      );
      if (mounted) Navigator.pop(context, true);
    } on ContractFailure catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: const Color(0xFF6A3242),
          ),
        );
      }
    }
  }

  StatusBadgeType _toBadgeType(ContractStatus status) {
    switch (status) {
      case ContractStatus.pending:
        return StatusBadgeType.pendente;
      case ContractStatus.approved:
        return StatusBadgeType.assinado;
      case ContractStatus.cancelled:
        return StatusBadgeType.cancelado;
    }
  }

  Widget _buildSino() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      child: const Icon(
        Icons.notifications_outlined,
        color: AppColors.white,
        size: 22,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:niccioli/app/models/contract.dart';
import 'package:niccioli/app/models/transport_profile.dart';
import 'package:niccioli/app/services/auth_service.dart';
import 'package:niccioli/app/services/contract_service.dart';
import 'package:niccioli/app/services/transport_service.dart';
import 'package:niccioli/app/theme/app_colors.dart';
import 'package:niccioli/app/views/widgets/status_badge.dart';
import 'package:niccioli/app/widgets/app_button.dart';
import 'package:url_launcher/url_launcher.dart';

enum _Vista { lista, detalhe }

class ContratoAluno extends StatefulWidget {
  const ContratoAluno({super.key});

  @override
  State<ContratoAluno> createState() => _ContratoAlunoState();
}

class _ContratoAlunoState extends State<ContratoAluno> {
  _Vista _vista = _Vista.lista;
  Contract? _selected;
  TransportProfile? _transport;
  List<Contract> _contracts = const [];
  bool _isLoading = true;
  String? _error;
  bool _isUploading = false;
  ContractStatus? _activeFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final transport =
          await TransportService.instance.loadCurrentStudentTransport();
      if (!mounted) return;
      if (transport == null) {
        setState(() {
          _transport = null;
          _contracts = const [];
          _isLoading = false;
        });
        return;
      }
      final uid = AuthService.instance.currentUser?.uid ?? '';
      final contracts =
          await ContractService.instance.listContracts(transport.id, uid);
      if (mounted) {
        setState(() {
          _transport = transport;
          _contracts = contracts;
          _isLoading = false;
        });
      }
    } on ContractFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  int get _totalPendentes =>
      _contracts.where((c) => c.status == ContractStatus.pending).length;
  int get _totalAprovados =>
      _contracts.where((c) => c.status == ContractStatus.approved).length;

  List<Contract> get _filtered {
    if (_activeFilter == null) return _contracts;
    return _contracts.where((c) => c.status == _activeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _vista == _Vista.lista ? _buildLista() : _buildDetalhe(),
    );
  }

  // ─── LISTA ──────────────────────────────────────────────────────────────────

  Widget _buildLista() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListaHeader(),
          _buildFilterChips(),
          const Divider(
            color: Colors.white12,
            thickness: 1,
            height: 1,
          ),
          Expanded(child: _buildListaBody()),
        ],
      ),
    );
  }

  Widget _buildListaHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Consultar Contratos',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Acompanhe seus contratos de transporte',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          _buildSino(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final options = <ContractStatus?>[null, ContractStatus.approved, ContractStatus.pending, ContractStatus.cancelled];
    final labels = ['Todos', 'Assinado', 'Pendentes', 'Cancelados'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(options.length, (i) {
            final isActive = _activeFilter == options[i];
            return GestureDetector(
              onTap: () => setState(() => _activeFilter = options[i]),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.orange : const Color(0xFF0D1F3C),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildListaBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _load,
              child: const Text(
                'Tentar novamente',
                style: TextStyle(color: AppColors.orange),
              ),
            ),
          ],
        ),
      );
    }
    if (_transport == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              color: Colors.white.withValues(alpha: 0.2),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum transporte vinculado',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }
    final contracts = _filtered;

    if (contracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              color: Colors.white.withValues(alpha: 0.2),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _activeFilter != null
                  ? 'Nenhum contrato nesta categoria'
                  : 'Nenhum contrato disponível',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_activeFilter == null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('$_totalPendentes', 'Aguardando\nAssinatura'),
                ),
                const SizedBox(width: 10),
                Expanded(child: _buildStatCard('$_totalAprovados', 'Assinados')),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard('${_contracts.length}', 'Total de\nContratos'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          ...contracts.map((c) => _buildCard(c)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String numero, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            numero,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Contract c) {
    return GestureDetector(
      onTap: () => setState(() {
        _selected = c;
        _vista = _Vista.detalhe;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1F3C),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _buildIcone(c.status),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.fileName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(c.startDate)} — ${_formatDate(c.endDate)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${c.monthlyValue.toStringAsFixed(2).replaceAll('.', ',')}  •  venc. dia ${c.paymentDay}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildBadge(c.status),
          ],
        ),
      ),
    );
  }

  Widget _buildIcone(ContractStatus status) {
    Color bg;
    Color iconColor;
    IconData icon;
    switch (status) {
      case ContractStatus.pending:
        bg = AppColors.orange.withValues(alpha: 0.15);
        iconColor = AppColors.orange;
        icon = Icons.article_outlined;
      case ContractStatus.approved:
        bg = const Color(0xFF1D5E52);
        iconColor = const Color(0xFF42E21E);
        icon = Icons.check_circle_outline;
      case ContractStatus.cancelled:
        bg = const Color(0xFF6A3242);
        iconColor = const Color(0xFFFF2B2B);
        icon = Icons.cancel_outlined;
    }
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }

  Widget _buildBadge(ContractStatus status) {
    StatusBadgeType type;
    switch (status) {
      case ContractStatus.pending:
        type = StatusBadgeType.pendente;
      case ContractStatus.approved:
        type = StatusBadgeType.assinado;
      case ContractStatus.cancelled:
        type = StatusBadgeType.cancelado;
    }
    return StatusBadge(
      status: type,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      textStyle: const TextStyle(fontSize: 11),
    );
  }

  // ─── DETALHE ─────────────────────────────────────────────────────────────────

  Widget _buildDetalhe() {
    final c = _selected!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _vista = _Vista.lista),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                _buildSino(),
              ],
            ),
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
            Row(
              children: [
                _buildBadge(c.status),
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
            ),
            const SizedBox(height: 20),
            _buildDetalheDados(c),
            const SizedBox(height: 16),
            if (c.status == ContractStatus.pending) _buildDetalheAssinatura(c),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalheDados(Contract c) {
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
          _buildDetalheLabel('DADOS DO CONTRATO'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDadoItem('INÍCIO', _formatDate(c.startDate))),
              Expanded(child: _buildDadoItem('FIM', _formatDate(c.endDate))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDadoItem(
                  'MENSALIDADE',
                  'R\$ ${c.monthlyValue.toStringAsFixed(2).replaceAll('.', ',')}',
                ),
              ),
              Expanded(
                child: _buildDadoItem('VENCIMENTO', 'Dia ${c.paymentDay}'),
              ),
            ],
          ),
          if (c.observations != null && c.observations!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildDadoItem('OBSERVAÇÕES', c.observations!),
          ],
        ],
      ),
    );
  }

  Widget _buildDetalheAssinatura(Contract c) {
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
          _buildDetalheLabel('ASSINATURA'),
          const SizedBox(height: 16),
          Text(
            '1. Baixe o contrato, assine via gov.br e envie o PDF assinado.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          AppOutlinedButton(
            label: 'Baixar contrato',
            onPressed: () => _launchUrl(c.fileUrl),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white12, thickness: 1),
          ),
          Text(
            '2. Após assinar, envie o PDF assinado:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          if (_isUploading) ...[
            const LinearProgressIndicator(
              backgroundColor: Color(0xFF091525),
              color: AppColors.orange,
            ),
            const SizedBox(height: 12),
            Text(
              'Enviando...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ] else
            AppFilledButton(
              label: 'Enviar PDF assinado',
              onPressed: () => _uploadSigned(c),
            ),
        ],
      ),
    );
  }

  Widget _buildDadoItem(String label, String valor) {
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

  Widget _buildDetalheLabel(String texto) {
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

  Future<void> _uploadSigned(Contract contract) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível ler o arquivo. Tente novamente.'),
            backgroundColor: Color(0xFF6A3242),
          ),
        );
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      final transport = _transport!;
      final uid = AuthService.instance.currentUser?.uid ?? '';
      await ContractService.instance.uploadSignedPdf(
        transportId: transport.id,
        driverUid: transport.driverUid,
        studentId: uid,
        contractId: contract.id,
        bytes: file.bytes!,
        original: contract,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contrato assinado enviado com sucesso!'),
            backgroundColor: Color(0xFF1D5E52),
          ),
        );
        setState(() {
          _vista = _Vista.lista;
          _selected = null;
          _isUploading = false;
        });
        await _load();
      }
    } on ContractFailure catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: const Color(0xFF6A3242),
          ),
        );
      }
    }
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

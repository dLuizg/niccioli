import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:niccioli/app/screens/financeiro/financeiro_screen.dart';
import 'package:niccioli/app/theme/app_colors.dart';
import 'package:niccioli/app/views/widgets/status_badge.dart';

class BoletoDetalheScreen extends StatefulWidget {
  final String studentUid;
  final String nomeAluno;
  final String transportDocId;

  const BoletoDetalheScreen({
    super.key,
    required this.studentUid,
    required this.nomeAluno,
    required this.transportDocId,
  });

  @override
  State<BoletoDetalheScreen> createState() => _BoletoDetalheScreenState();
}

class _BoletoDetalheScreenState extends State<BoletoDetalheScreen> {
  StatusBadgeType? _filtroAtivo;
  late Future<Map<String, StatusBoleto>> _statusFuture;

  static const _meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril',
    'Maio', 'Junho', 'Julho', 'Agosto',
    'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _statusFuture = _carregarStatus();
  }

  Future<Map<String, StatusBoleto>> _carregarStatus() async {
    if (widget.transportDocId.isEmpty) return {};

    final doc = await FirebaseFirestore.instance
        .collection('transport')
        .doc(widget.transportDocId)
        .get();

    final data = doc.data();
    if (data == null) return {};

    final byMonth = data['boletoStatusByMonth'] as Map<String, dynamic>?;
    if (byMonth == null) return {};

    final studentMap = byMonth[widget.studentUid] as Map<String, dynamic>?;
    if (studentMap == null) return {};

    return studentMap.map(
      (k, v) => MapEntry(k, StatusBoletoExt.fromString(v as String?)),
    );
  }

  StatusBadgeType _toBadgeType(StatusBoleto s) {
    switch (s) {
      case StatusBoleto.pago:
        return StatusBadgeType.pago;
      case StatusBoleto.aVencer:
        return StatusBadgeType.aVencer;
      case StatusBoleto.vencido:
        return StatusBadgeType.vencido;
      case StatusBoleto.emAberto:
        return StatusBadgeType.emAberto;
    }
  }

  StatusBoleto _fromBadgeType(StatusBadgeType t) {
    switch (t) {
      case StatusBadgeType.pago:
        return StatusBoleto.pago;
      case StatusBadgeType.aVencer:
        return StatusBoleto.aVencer;
      case StatusBadgeType.vencido:
        return StatusBoleto.vencido;
      default:
        return StatusBoleto.emAberto;
    }
  }

  String _monthKey(int month) {
    final year = DateTime.now().year;
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.nomeAluno,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, StatusBoleto>>(
        future: _statusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          }

          final statusMap = snapshot.data ?? {};

          final filtroStatus = _filtroAtivo != null
              ? _fromBadgeType(_filtroAtivo!)
              : null;

          final mesesVisiveis = List.generate(12, (i) => i + 1).where((m) {
            if (filtroStatus == null) return true;
            final key = _monthKey(m);
            final status = statusMap[key] ?? StatusBoleto.emAberto;
            return status == filtroStatus;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _FiltroBadgeBar(
                filtroAtivo: _filtroAtivo,
                onFiltroChanged: (t) => setState(() => _filtroAtivo = t),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: mesesVisiveis.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum boleto encontrado.',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: mesesVisiveis.length,
                        itemBuilder: (_, index) {
                          final mes = mesesVisiveis[index];
                          final key = _monthKey(mes);
                          final status = statusMap[key] ?? StatusBoleto.emAberto;
                          return _MesAccordion(
                            nomeMes: _meses[mes - 1],
                            mes: mes,
                            status: status,
                            badgeType: _toBadgeType(status),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- Filtro de badges no topo ---

class _FiltroBadgeBar extends StatelessWidget {
  final StatusBadgeType? filtroAtivo;
  final ValueChanged<StatusBadgeType?> onFiltroChanged;

  const _FiltroBadgeBar({
    required this.filtroAtivo,
    required this.onFiltroChanged,
  });

  static const _opcoes = [
    StatusBadgeType.emAberto,
    StatusBadgeType.aVencer,
    StatusBadgeType.vencido,
    StatusBadgeType.pago,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _BadgeFiltroChip(
            label: 'Todos',
            selecionado: filtroAtivo == null,
            onTap: () => onFiltroChanged(null),
          ),
          ..._opcoes.map(
            (tipo) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => onFiltroChanged(
                  filtroAtivo == tipo ? null : tipo,
                ),
                child: Container(
                  decoration: filtroAtivo == tipo
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        )
                      : null,
                  child: Opacity(
                    opacity: filtroAtivo == null || filtroAtivo == tipo ? 1.0 : 0.45,
                    child: StatusBadge(status: tipo),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeFiltroChip extends StatelessWidget {
  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  const _BadgeFiltroChip({
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selecionado ? const Color(0xFFD4A017) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selecionado ? const Color(0xFFD4A017) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selecionado ? Colors.black : Colors.white70,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// --- Accordion por mês ---

class _MesAccordion extends StatelessWidget {
  final String nomeMes;
  final int mes;
  final StatusBoleto status;
  final StatusBadgeType badgeType;

  const _MesAccordion({
    required this.nomeMes,
    required this.mes,
    required this.status,
    required this.badgeType,
  });

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final vencimento = '20/${mes.toString().padLeft(2, '0')}/$year';

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.white10,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF162030),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: Colors.white54,
          collapsedIconColor: Colors.white38,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  nomeMes,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadge(
                status: badgeType,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 4),
            ],
          ),
          children: [
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vencimento: $vencimento',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'R\$ 399,99',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                StatusBadge(status: badgeType),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

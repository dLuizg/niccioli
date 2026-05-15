import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:niccioli/app/pages/financeiro/financeiro_motorista_screen.dart';
import 'package:niccioli/app/theme/app_colors.dart';
import 'package:niccioli/app/views/widgets/status_badge.dart';

// --- Data holder ---

class _MesInfo {
  final StatusBoleto status;
  final String? comprovanteUrl;
  final DocumentReference? parcelaRef;
  const _MesInfo({required this.status, this.comprovanteUrl, this.parcelaRef});
}

// --- Screen ---

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

  static const _meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril',
    'Maio', 'Junho', 'Julho', 'Agosto',
    'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  Stream<Map<String, _MesInfo>> _dadosStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentUid)
        .collection('parcelas')
        .snapshots()
        .asyncMap((parcelasSnap) async {
          // Fetch transport doc for base status (best-effort)
          Map<String, StatusBoleto> statusBase = {};
          if (widget.transportDocId.isNotEmpty) {
            final transportDoc = await FirebaseFirestore.instance
                .collection('transport')
                .doc(widget.transportDocId)
                .get();
            final d = transportDoc.data();
            final byMonth = d?['boletoStatusByMonth'] as Map<String, dynamic>?;
            final studentMap =
                byMonth?[widget.studentUid] as Map<String, dynamic>?;
            statusBase = studentMap?.map(
                  (k, v) => MapEntry(k, StatusBoletoExt.fromString(v as String?)),
                ) ??
                {};
          }

          // Build result: parcela fields are source of truth for pago/comprovante
          final result = <String, _MesInfo>{
            for (final e in statusBase.entries)
              e.key: _MesInfo(status: e.value),
          };

          for (final doc in parcelasSnap.docs) {
            final d = doc.data();
            final dataStr = d['data'] as String?;
            if (dataStr == null) continue;
            final partes = dataStr.split('/');
            if (partes.length != 3) continue;
            // Derive month key YYYY-MM from data field dd/MM/yyyy
            final mesKey =
                '${partes[2]}-${partes[1].padLeft(2, '0')}';
            final pago = (d['pago'] as bool?) ?? false;
            final comprovanteUrl = d['comprovante_url'] as String?;
            final statusFallback =
                result[mesKey]?.status ?? StatusBoleto.emAberto;
            result[mesKey] = _MesInfo(
              status: pago ? StatusBoleto.pago : statusFallback,
              comprovanteUrl: comprovanteUrl,
              parcelaRef: doc.reference,
            );
          }

          return result;
        });
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

  Future<void> _contestarComprovante(
    BuildContext context,
    DocumentReference ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF162030),
        title: const Text(
          'Contestar comprovante',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'O comprovante será rejeitado e o aluno precisará enviar um novo.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Contestar',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.update({
        'pago': false,
        'comprovante_url': FieldValue.delete(),
        'comprovante_contestado': true,
      });
    }
  }

  // Pago sempre respeita. Para meses já passados não pagos → vencido.
  // Mês atual não pago → aVencer. Futuros → emAberto.
  StatusBoleto _statusEfetivo(int mes, StatusBoleto? statusSalvo) {
    if (statusSalvo == StatusBoleto.pago) return StatusBoleto.pago;
    final now = DateTime.now();
    final mesDate = DateTime(now.year, mes);
    final mesAtual = DateTime(now.year, now.month);
    if (mesDate.isBefore(mesAtual)) return StatusBoleto.vencido;
    if (mesDate.isAtSameMomentAs(mesAtual)) return StatusBoleto.aVencer;
    return statusSalvo ?? StatusBoleto.emAberto;
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
      body: StreamBuilder<Map<String, _MesInfo>>(
        stream: _dadosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          }

          final dados = snapshot.data ?? {};

          final filtroStatus = _filtroAtivo != null
              ? _fromBadgeType(_filtroAtivo!)
              : null;

          final mesesVisiveis = List.generate(12, (i) => i + 1).where((m) {
            if (filtroStatus == null) return true;
            final key = _monthKey(m);
            final status = _statusEfetivo(m, dados[key]?.status);
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
                          final info = dados[key];
                          final status = _statusEfetivo(mes, info?.status);
                          return _MesAccordion(
                            nomeMes: _meses[mes - 1],
                            mes: mes,
                            status: status,
                            badgeType: _toBadgeType(status),
                            comprovanteUrl: info?.comprovanteUrl,
                            onContestar: info?.parcelaRef != null &&
                                    info?.comprovanteUrl != null
                                ? () => _contestarComprovante(
                                    context, info!.parcelaRef!)
                                : null,
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
  final String? comprovanteUrl;
  final VoidCallback? onContestar;

  const _MesAccordion({
    required this.nomeMes,
    required this.mes,
    required this.status,
    required this.badgeType,
    this.comprovanteUrl,
    this.onContestar,
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
            const SizedBox(height: 12),
            _ComprovanteRow(comprovanteUrl: comprovanteUrl),
            if (onContestar != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onContestar,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFE53935).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel_outlined,
                          color: Color(0xFFE53935), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Contestar comprovante',
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Comprovante row ---

class _ComprovanteRow extends StatelessWidget {
  final String? comprovanteUrl;

  const _ComprovanteRow({this.comprovanteUrl});

  @override
  Widget build(BuildContext context) {
    if (comprovanteUrl != null) {
      return GestureDetector(
        onTap: () => launchUrl(
          Uri.parse(comprovanteUrl!),
          mode: LaunchMode.externalApplication,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, color: AppColors.orange, size: 16),
              SizedBox(width: 8),
              Text(
                'Ver comprovante',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const Row(
      children: [
        Icon(Icons.receipt_long_outlined, color: Colors.white24, size: 16),
        SizedBox(width: 8),
        Text(
          'Sem comprovante enviado',
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      ],
    );
  }
}

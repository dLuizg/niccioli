// financeiro_screen.dart

import 'package:flutter/material.dart';
import 'package:niccioli/app/theme/app_colors.dart';
import 'package:niccioli/app/views/widgets/notification_badge.dart';
import 'package:niccioli/app/views/widgets/status_badge.dart';
import 'package:niccioli/app/screens/notification/notification_screen.dart';

// --- Model ---

class Parcela {
  final String data;
  final String nome;
  final double valor;
  final bool pago;

  const Parcela({
    required this.data,
    required this.nome,
    required this.valor,
    this.pago = false,
  });

  StatusBadgeType get status => _calcularStatus(data, pago: pago);

  static StatusBadgeType _calcularStatus(String data, {bool pago = false}) {
    if (pago) return StatusBadgeType.pago;

    final partes = data.split('/');
    final mes = int.parse(partes[1]);
    final ano = int.parse(partes[2]);

    final hoje = DateTime.now();
    final mesAtual = DateTime(hoje.year, hoje.month);
    final mesVencimento = DateTime(ano, mes);

    // Calcula mês seguinte sem overflow
    final mesSeguinte = hoje.month == 12
        ? DateTime(hoje.year + 1, 1)
        : DateTime(hoje.year, hoje.month + 1);

    debugPrint(
      'data=$data | venc=$mesVencimento | atual=$mesAtual | seguinte=$mesSeguinte',
    );

    if (mesVencimento == mesSeguinte) return StatusBadgeType.emAberto;
    if (mesVencimento == mesAtual) return StatusBadgeType.aVencer;
    if (mesVencimento.isBefore(mesAtual)) return StatusBadgeType.vencido;

    return StatusBadgeType.emAberto;
  }
}

// --- Screen ---

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  StatusBadgeType? _filtroAtivo;

  final List<Parcela> _parcelas = const [
    Parcela(
      data: '10/06/2026', // mês seguinte → emAberto
      nome: 'Niccioli Viagens e Turismos',
      valor: 399.99,
    ),
    Parcela(
      data: '15/05/2026', // mês atual → aVencer
      nome: 'Niccioli Viagens e Turismos',
      valor: 399.99,
    ),
    Parcela(
      data: '20/03/2026', // mês passado, não pago → vencido
      nome: 'Niccioli Viagens e Turismos',
      valor: 399.99,
    ),
    Parcela(
      data: '20/03/2026', // mês passado, pago → pago
      nome: 'Niccioli Viagens e Turismos',
      valor: 399.99,
      pago: true,
    ),
    Parcela(
      data: '10/05/2026', // mês atual, pago → pago
      nome: 'Niccioli Viagens e Turismos',
      valor: 199.99,
      pago: true,
    ),
  ];
  List<Parcela> get _parcelasFiltradas => _filtroAtivo == null
      ? _parcelas
      : _parcelas.where((p) => p.status == _filtroAtivo).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Consultar Boletos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          NotificationBadge(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificacaoTela()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _FiltroBar(
            filtroAtivo: _filtroAtivo,
            onFiltroChanged: (status) => setState(() => _filtroAtivo = status),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _parcelasFiltradas.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum boleto encontrado.',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _parcelasFiltradas.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 1,
                    ),
                    itemBuilder: (_, index) =>
                        _ParcelaItem(parcela: _parcelasFiltradas[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Filter Bar ---

class _FiltroBar extends StatelessWidget {
  final StatusBadgeType? filtroAtivo;
  final ValueChanged<StatusBadgeType?> onFiltroChanged;

  const _FiltroBar({required this.filtroAtivo, required this.onFiltroChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FiltroChip(
            label: 'Todos',
            ativo: filtroAtivo == null,
            onTap: () => onFiltroChanged(null),
          ),
          const SizedBox(width: 8),
          _FiltroChip(
            label: 'Em Aberto',
            ativo: filtroAtivo == StatusBadgeType.emAberto,
            onTap: () => onFiltroChanged(StatusBadgeType.emAberto),
          ),
          const SizedBox(width: 8),
          _FiltroChip(
            label: 'A Vencer',
            ativo: filtroAtivo == StatusBadgeType.aVencer,
            onTap: () => onFiltroChanged(StatusBadgeType.aVencer),
          ),
          const SizedBox(width: 8),
          _FiltroChip(
            label: 'Vencidos',
            ativo: filtroAtivo == StatusBadgeType.vencido,
            onTap: () => onFiltroChanged(StatusBadgeType.vencido),
          ),
          const SizedBox(width: 8),
          _FiltroChip(
            label: 'Pagos',
            ativo: filtroAtivo == StatusBadgeType.pago,
            onTap: () => onFiltroChanged(StatusBadgeType.pago),
          ),
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool ativo;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.ativo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: ativo ? const Color(0xFFD4A017) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ativo ? const Color(0xFFD4A017) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ativo ? Colors.black : Colors.white70,
            fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// --- Parcela Item ---

class _ParcelaItem extends StatelessWidget {
  final Parcela parcela;

  const _ParcelaItem({required this.parcela});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parcela.data,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  parcela.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'R\$ ${parcela.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusBadge(status: parcela.status),
        ],
      ),
    );
  }
}

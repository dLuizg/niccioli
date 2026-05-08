// financeiro_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:niccioli/app/theme/app_colors.dart';
import 'package:niccioli/app/views/widgets/notification_badge.dart';
import 'package:niccioli/app/screens/notification/notification_screen.dart';

// --- Model ---

class BoletoAluno {
  final String data;
  final String nomeAluno;
  final String universidade;

  const BoletoAluno({
    required this.data,
    required this.nomeAluno,
    required this.universidade,
  });
}

// --- Screen ---

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  String? _filtroAtivo;
  late final Future<List<BoletoAluno>> _alunosFuture;

  @override
  void initState() {
    super.initState();
    _alunosFuture = _carregarAlunos();
  }

  Future<List<BoletoAluno>> _carregarAlunos() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado.');

    // 1. Lê o documento de transporte do motorista logado
    final transportSnap = await FirebaseFirestore.instance
        .collection('transport')
        .where('driverUid', isEqualTo: uid)
        .limit(1)
        .get();

    if (transportSnap.docs.isEmpty) return <BoletoAluno>[];

    final transportData = transportSnap.docs.first.data();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // 2. Tenta studentSummaries (denormalizado, mesmo documento, sem N+1)
    final rawSummaries = transportData['studentSummaries'];
    if (rawSummaries is Map<String, dynamic> && rawSummaries.isNotEmpty) {
      final lista = rawSummaries.entries.map<BoletoAluno>((e) {
        final v = e.value as Map<String, dynamic>? ?? {};
        return BoletoAluno(
          data: today,
          nomeAluno: (v['name'] as String?) ?? '—',
          universidade: (v['university'] as String?) ?? '—',
        );
      }).toList();
      lista.sort((a, b) => a.nomeAluno.compareTo(b.nomeAluno));
      return lista;
    }

    // 3. Fallback: lê cada aluno na coleção users via studentUids
    final studentUids =
        (transportData['studentUids'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        <String>[];

    if (studentUids.isEmpty) return <BoletoAluno>[];

    final alunos = <BoletoAluno>[];
    for (final studentUid in studentUids) {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(studentUid)
          .get();
      final userData = userSnap.data();
      if (userData != null) {
        alunos.add(
          BoletoAluno(
            data: today,
            nomeAluno: (userData['name'] as String?) ?? '—',
            universidade: (userData['university'] as String?) ?? '—',
          ),
        );
      }
    }

    alunos.sort((a, b) => a.nomeAluno.compareTo(b.nomeAluno));
    return alunos;
  }

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
      body: FutureBuilder<List<BoletoAluno>>(
        future: _alunosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          setState(() => _alunosFuture = _carregarAlunos()),
                      child: const Text(
                        'Tentar novamente',
                        style: TextStyle(color: AppColors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final alunos = snapshot.data ?? [];
          final universidades = alunos
              .map((a) => a.universidade)
              .toSet()
              .toList();
          final alunosFiltrados = _filtroAtivo == null
              ? alunos
              : alunos.where((a) => a.universidade == _filtroAtivo).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _FiltroBar(
                universidades: universidades,
                filtroAtivo: _filtroAtivo,
                onFiltroChanged: (uni) => setState(() => _filtroAtivo = uni),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: alunosFiltrados.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum aluno encontrado.',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: alunosFiltrados.length,
                        separatorBuilder: (_, _) => Divider(
                          color: Colors.white.withValues(alpha: 0.08),
                          height: 1,
                        ),
                        itemBuilder: (_, index) =>
                            _AlunoItem(aluno: alunosFiltrados[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- Section Header ---

// --- Filter Bar ---

class _FiltroBar extends StatelessWidget {
  final List<String> universidades;
  final String? filtroAtivo;
  final ValueChanged<String?> onFiltroChanged;

  const _FiltroBar({
    required this.universidades,
    required this.filtroAtivo,
    required this.onFiltroChanged,
  });

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
          ...universidades.map(
            (uni) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FiltroChip(
                label: uni,
                ativo: filtroAtivo == uni,
                onTap: () => onFiltroChanged(uni),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.add, color: Colors.white70, size: 16),
            ),
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

// --- Aluno Item ---

class _AlunoItem extends StatelessWidget {
  final BoletoAluno aluno;

  const _AlunoItem({required this.aluno});

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
                  aluno.data,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  aluno.nomeAluno,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF162030),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              aluno.universidade,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

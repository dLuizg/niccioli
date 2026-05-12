import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:niccioli/screens/notification/notification_screen.dart';
import 'package:niccioli/theme/app_colors.dart';
import 'package:niccioli/views/widgets/notification_badge.dart';
import 'package:niccioli/views/widgets/status_badge.dart';

// --- Model ---

class Parcela {
  final String id;
  final DocumentReference ref;
  final String data;
  final String nome;
  final double valor;
  final bool pago;
  final String? comprovanteUrl;

  const Parcela({
    required this.id,
    required this.ref,
    required this.data,
    required this.nome,
    required this.valor,
    this.pago = false,
    this.comprovanteUrl,
  });

  factory Parcela.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Parcela(
      id: doc.id,
      ref: doc.reference,
      data: map['data'] as String,
      nome: map['nome'] as String? ?? 'Niccioli Viagens e Turismos',
      valor: (map['valor'] as num).toDouble(),
      pago: (map['pago'] as bool?) ?? false,
      comprovanteUrl: map['comprovante_url'] as String?,
    );
  }

  bool get comprovanteEnviado =>
      comprovanteUrl != null && comprovanteUrl!.isNotEmpty;

  StatusBadgeType get status {
    if (pago) return StatusBadgeType.pago;
    if (comprovanteEnviado) return StatusBadgeType.pendente;
    return _calcularPorData(data);
  }

  static StatusBadgeType _calcularPorData(String data) {
    final partes = data.split('/');
    final mes = int.parse(partes[1]);
    final ano = int.parse(partes[2]);

    final hoje = DateTime.now();
    final mesAtual = DateTime(hoje.year, hoje.month);
    final mesVencimento = DateTime(ano, mes);
    final mesSeguinte = hoje.month == 12
        ? DateTime(hoje.year + 1, 1)
        : DateTime(hoje.year, hoje.month + 1);

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

  Stream<List<Parcela>> _parcelasStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('parcelas')
        .orderBy('mes')
        .snapshots()
        .map((snap) => snap.docs.map(Parcela.fromFirestore).toList());
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
      body: StreamBuilder<List<Parcela>>(
        stream: _parcelasStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Erro ao carregar boletos.',
                style: TextStyle(color: Colors.white38),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum boleto encontrado.',
                style: TextStyle(color: Colors.white38),
              ),
            );
          }

          final todas = snapshot.data!;
          final filtradas = _filtroAtivo == null
              ? todas
              : todas.where((p) => p.status == _filtroAtivo).toList();

          return Column(
            children: [
              const SizedBox(height: 12),
              _FiltroBar(
                filtroAtivo: _filtroAtivo,
                onFiltroChanged: (s) => setState(() => _filtroAtivo = s),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtradas.isEmpty
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
                        itemCount: filtradas.length,
                        separatorBuilder: (_, _) => Divider(
                          color: Colors.white.withValues(alpha: 0.08),
                          height: 1,
                        ),
                        itemBuilder: (_, index) =>
                            _ParcelaItem(parcela: filtradas[index]),
                      ),
              ),
            ],
          );
        },
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
            label: 'Pendente',
            ativo: filtroAtivo == StatusBadgeType.pendente,
            onTap: () => onFiltroChanged(StatusBadgeType.pendente),
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
    final podeEnviar = !parcela.pago;

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: parcela.status),
              if (podeEnviar) ...[
                const SizedBox(height: 8),
                _BotaoComprovante(parcela: parcela),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// --- Botão Comprovante ---

class _BotaoComprovante extends StatelessWidget {
  final Parcela parcela;

  const _BotaoComprovante({required this.parcela});

  @override
  Widget build(BuildContext context) {
    final jaEnviou = parcela.comprovanteEnviado;

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: jaEnviou
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: jaEnviou ? Colors.white24 : AppColors.orange,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              jaEnviou
                  ? Icons.check_circle_outline
                  : Icons.upload_file_outlined,
              size: 13,
              color: jaEnviou ? Colors.white38 : AppColors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              jaEnviou ? 'Comprovante enviado' : 'Enviar comprovante',
              style: TextStyle(
                fontSize: 11,
                color: jaEnviou ? Colors.white38 : AppColors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    if (parcela.comprovanteEnviado) {
      _mostrarComprovante(context);
    } else {
      _mostrarBottomSheet(context);
    }
  }

  void _mostrarComprovante(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'Comprovante enviado',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Seu comprovante está em análise. Aguarde a confirmação.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
    );
  }

  void _mostrarBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ComprovanteBottomSheet(parcela: parcela),
    );
  }
}

// --- Bottom Sheet Upload ---

class _ComprovanteBottomSheet extends StatefulWidget {
  final Parcela parcela;

  const _ComprovanteBottomSheet({required this.parcela});

  @override
  State<_ComprovanteBottomSheet> createState() =>
      _ComprovanteBottomSheetState();
}

class _ComprovanteBottomSheetState extends State<_ComprovanteBottomSheet> {
  bool _carregando = false;
  String? _nomeArquivo;

  Future<void> _selecionarEEnviar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;

    setState(() {
      _carregando = true;
      _nomeArquivo = file.name;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'sem_uid';
      final ext = file.extension ?? 'jpg';
      final path = 'users/$uid/comprovantes/${widget.parcela.id}.$ext';

      final ref = FirebaseStorage.instance.ref(path);
      await ref.putData(file.bytes!);
      final url = await ref.getDownloadURL();

      await widget.parcela.ref.update({
        'comprovante_url': url,
        'pago': true,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar comprovante.')),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Enviar comprovante',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.parcela.nome}  •  ${widget.parcela.data}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'R\$ ${widget.parcela.valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _carregando ? null : _selecionarEEnviar,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _carregando
                    ? Colors.white.withValues(alpha: 0.05)
                    : AppColors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _carregando ? Colors.white24 : AppColors.orange,
                ),
              ),
              child: _carregando
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.orange,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.upload_file_outlined,
                          color: AppColors.orange,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _nomeArquivo ?? 'Selecionar arquivo',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'JPG, PNG ou PDF',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'O pagamento será confirmado após análise.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

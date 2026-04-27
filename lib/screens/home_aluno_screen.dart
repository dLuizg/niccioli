import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';

enum HomeStatus { pending, confirmed, notRequested, timeLimit }

class HomeAlunoScreen extends StatefulWidget {
  const HomeAlunoScreen({super.key});

  @override
  State<HomeAlunoScreen> createState() => _HomeAlunoScreenState();
}

class _HomeAlunoScreenState extends State<HomeAlunoScreen> {
  HomeStatus _status = HomeStatus.pending;
  bool _showCancelDialog = false;

  // Dados da van (virão do backend)
  final String _vanName = 'Van na fazenda';
  final int _boardedCount = 1;
  final int _totalCount = 7;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom Dia!';
    if (hour < 18) return 'Boa Tarde!';
    return 'Boa Noite!';
  }

  String get _greetingSubtitle {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Tenha um ótimo dia!';
    if (hour < 18) return 'Tenha uma ótima tarde!';
    return 'Tenha uma ótima noite!';
  }

  String get _statusSubtitle {
    switch (_status) {
      case HomeStatus.pending:
        return _greetingSubtitle;
      case HomeStatus.confirmed:
        return 'Faça seu check-in';
      case HomeStatus.notRequested:
        return 'Não solicitado';
      case HomeStatus.timeLimit:
        return 'Horário limite atingido entre\nem contato com o motorista';
    }
  }

  String _getDayName(DateTime date) {
    const days = [
      'Domingo',
      'Segunda-Feira',
      'Terça-Feira',
      'Quarta-Feira',
      'Quinta-Feira',
      'Sexta-Feira',
      'Sábado',
    ];
    return days[date.weekday % 7];
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  void _onConfirm() => setState(() => _status = HomeStatus.confirmed);
  void _onNotGoing() => setState(() => _status = HomeStatus.notRequested);
  void _onCancelTap() => setState(() => _showCancelDialog = true);
  void _onKeepTransport() => setState(() => _showCancelDialog = false);
  void _onRequest() => setState(() => _status = HomeStatus.pending);

  void _onConfirmCancel() {
    setState(() {
      _showCancelDialog = false;
      _status = HomeStatus.notRequested;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(now),
                Expanded(child: _buildBody(bottomPadding)),
              ],
            ),
          ),
          if (_showCancelDialog) _buildCancelOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar(DateTime now) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getDayName(now),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDate(now),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withOpacity(0.4),
              ),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double bottomPadding) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            _greeting,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _status == HomeStatus.timeLimit
                  ? AppColors.white
                  : AppColors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const Spacer(flex: 3),
          _buildStatusContent(),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildStatusContent() {
    switch (_status) {
      case HomeStatus.pending:
        return _buildPendingContent();
      case HomeStatus.confirmed:
        return _buildConfirmedContent();
      case HomeStatus.notRequested:
        return _buildNotRequestedContent();
      case HomeStatus.timeLimit:
        return _buildTimeLimitContent();
    }
  }

  Widget _buildPendingContent() {
    return Column(
      children: [
        const Text(
          'Você vai hoje?',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        AppDualOutlinedButton(
          label1: 'CONFIRMAR',
          onPressed1: _onConfirm,
          label2: 'NÃO VOU',
          onPressed2: _onNotGoing,
        ),
      ],
    );
  }

  Widget _buildConfirmedContent() {
    final vanFull = _boardedCount == _totalCount;

    return Column(
      children: [
        Text(
          _vanName,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        _buildCounterBadge(),
        const SizedBox(height: 24),
        if (!vanFull) ...[
          const Text(
            'Aguarde a chegada da van no\nseu local de embarque',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          _outlinedButton(label: 'Já Fui Liberado(a)', onPressed: () {}),
        ] else ...[
          const Text(
            'Você está na van?',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _outlinedButton(label: 'SIM, ESTOU', onPressed: () {}),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Não vou voltar',
            style: TextStyle(
              color: AppColors.white,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.white,
              fontSize: 13,
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Vou pegar a van em outro lugar',
            style: TextStyle(
              color: AppColors.white,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.white,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterBadge() {
    final current = _boardedCount.toString().padLeft(2, '0');
    final total = _totalCount.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.orange, width: 1.5),
      ),
      child: Text(
        '$current/$total',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNotRequestedContent() {
    return _outlinedButton(label: 'Solicitar', onPressed: _onRequest);
  }

  Widget _buildTimeLimitContent() {
    return _outlinedButton(label: 'Entrar em contato', onPressed: () {});
  }

  Widget _outlinedButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.orange, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        foregroundColor: AppColors.orange,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCancelOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.dialogOrange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tem certeza que deseja\ncancelar?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Se você cancelar, ficará marcado\ndireto como "Não Solicitado"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _dialogButton(
                          label: 'Entendo,\nquero Cancelar!',
                          onPressed: _onConfirmCancel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dialogButton(
                          label: 'Quero Manter o\ntransporte!',
                          onPressed: _onKeepTransport,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        elevation: 0,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

}

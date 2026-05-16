import 'dart:async';
import 'package:flutter/material.dart';
import 'package:niccioli/app/models/transport_profile.dart'
    show TransportStudentSummary;
import 'package:niccioli/app/pages/notification/notification_screen.dart';
import 'package:niccioli/app/services/auth_service.dart';
import 'package:niccioli/app/services/transport_service.dart';
import 'package:niccioli/app/views/widgets/notification_badge.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/van/contador_badge.dart';
import '../../views/widgets/data_badge.dart';
import 'package:niccioli/screens/IA/chat_screen.dart';

// Estados baseados em horário (mesmo padrão de home_aluno) + estados de rota:
//
// antesDoHorario → 00:01 até defaultListDeadline  (lista IDA em formação)
// listaFechada   → defaultListDeadline até 20:00   (lista IDA final, INICIAR disponível)
// emRota         → rota de IDA ativa (user-triggered)
// aguardandoVolta→ 20:01 até 00:00                 (lista VOLTA — quem volta hoje)
// emRotaVolta    → rota de VOLTA ativa (user-triggered)
enum _EstadoMotorista {
  antesDoHorario,
  listaFechada,
  emRota,
  aguardandoVolta,
  emRotaVolta,
}

class HomeMotorista extends StatefulWidget {
  const HomeMotorista({super.key});

  @override
  State<HomeMotorista> createState() => _HomeMotoristaState();
}

class _HomeMotoristaState extends State<HomeMotorista> {
  _EstadoMotorista _estado = _EstadoMotorista.antesDoHorario;

  // defaultListDeadline do motorista ex: "17:00"
  String? _deadline;

  // Lista de alunos que confirmaram IDA (outboundStatus == 'confirmed')
  List<TransportStudentSummary> _idaStudents = [];

  // Lista de alunos esperados na VOLTA:
  // confirmaram IDA E não disseram explicitamente que não voltam
  List<TransportStudentSummary> _voltaStudents = [];

  // Paradas e contador para a rota ativa (ida ou volta)
  List<String> _paradas = [];
  int _paradaAtualIndex = 0;
  int _alunosNaVan = 0;

  bool _isLoading = true;
  String? _errorMessage;

  // Timer que verifica a cada minuto se o horário cruzou um limiar (RN01)
  Timer? _timer;

  // ─── LÓGICA DE HORÁRIO (mesmo padrão de home_aluno) ──────────────────────────

  // Converte "HH:mm" em minutos totais do dia
  static int _deadlineParaMinutos(String deadline) {
    final parts = deadline.split(':');
    if (parts.length != 2) return 1020; // fallback: 17:00
    final h = int.tryParse(parts[0]) ?? 17;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  // Calcula o estado baseado no horário atual — não substitui estados de rota ativos
  _EstadoMotorista _calcularEstado() {
    // Rotas ativas não são interrompidas pelo timer
    if (_estado == _EstadoMotorista.emRota) return _EstadoMotorista.emRota;
    if (_estado == _EstadoMotorista.emRotaVolta) {
      return _EstadoMotorista.emRotaVolta;
    }
    return _calcularEstadoTempo();
  }

  _EstadoMotorista _calcularEstadoTempo() {
    final now = DateTime.now();
    final total = now.hour * 60 + now.minute;
    // 20:01–00:00 → turno da volta (mesmo limite de home_aluno "depois")
    if (total == 0 || total > 1200) return _EstadoMotorista.aguardandoVolta;
    // defaultListDeadline–20:00 → lista fechada
    final limiteMin = _deadlineParaMinutos(_deadline ?? '17:00');
    if (total >= limiteMin) return _EstadoMotorista.listaFechada;
    // 00:01–deadline → antes do horário
    return _EstadoMotorista.antesDoHorario;
  }

  String get _deadlineFormatado => _deadline ?? '17:00';

  // Retorna os alunos da lista ativa (ida ou volta) conforme estado
  List<TransportStudentSummary> get _activeStudents =>
      (_estado == _EstadoMotorista.emRotaVolta ||
              _estado == _EstadoMotorista.aguardandoVolta)
          ? _voltaStudents
          : _idaStudents;

  // ─── LIFECYCLE ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();

    // Verifica a cada minuto se o limiar de horário foi cruzado (RN01)
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final novoEstado = _calcularEstado();
      if (novoEstado != _estado) {
        setState(() => _estado = novoEstado);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transport =
          await TransportService.instance.loadCurrentDriverTransport();

      if (transport == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Nenhum transporte encontrado.';
          });
        }
        return;
      }

      final presences =
          await TransportService.instance.loadTodayDriverPresences();

      // IDA: confirmaram outboundStatus == 'confirmed'
      final confirmedUids = presences.entries
          .where((e) => e.value.outboundStatus == 'confirmed')
          .map((e) => e.key)
          .toSet();

      final idaList = transport.studentSummaries.values
          .where((s) => confirmedUids.contains(s.uid))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      // VOLTA: foram na ida E não disseram explicitamente que não voltam
      final naoVoltamUids = presences.entries
          .where((e) => e.value.returnStatus == 'notReturning')
          .map((e) => e.key)
          .toSet();

      final voltaList = idaList
          .where((s) => !naoVoltamUids.contains(s.uid))
          .toList();

      // Paradas da ida derivadas do defaultPickupPoint dos alunos confirmados
      final stops = idaList
          .map((s) => s.defaultPickupPoint ?? s.university ?? 'Ponto')
          .toSet()
          .toList()
        ..sort();

      if (mounted) {
        setState(() {
          _deadline = transport.defaultListDeadline;
          _idaStudents = idaList;
          _voltaStudents = voltaList;
          _paradas = stops;
          _estado = _calcularEstadoTempo();
          _isLoading = false;
        });
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.message;
        });
      }
    }
  }

  // ─── LÓGICA DE ROTA ──────────────────────────────────────────────────────────

  List<TransportStudentSummary> _studentsAtCurrentStop() {
    if (_paradas.isEmpty) return _activeStudents;
    final parada = _paradas[_paradaAtualIndex];
    return _activeStudents
        .where(
          (s) =>
              (s.defaultPickupPoint ?? s.university ?? 'Ponto') == parada,
        )
        .toList();
  }

  void _iniciarRota({required bool isVolta}) {
    // Recalcula paradas para o turno que está sendo iniciado
    final students = isVolta ? _voltaStudents : _idaStudents;
    final stops = students
        .map((s) => s.defaultPickupPoint ?? s.university ?? 'Ponto')
        .toSet()
        .toList()
      ..sort();

    setState(() {
      _paradas = stops;
      _paradaAtualIndex = 0;
      _alunosNaVan = 0;
      _estado = isVolta
          ? _EstadoMotorista.emRotaVolta
          : _EstadoMotorista.emRota;
    });
  }

  void _irParaProximoPonto() {
    final aqui = _studentsAtCurrentStop().length;
    setState(() {
      _alunosNaVan += aqui;
      if (_paradaAtualIndex < _paradas.length - 1) {
        _paradaAtualIndex++;
      }
    });
  }

  void _finalizarRota() {
    final aqui = _studentsAtCurrentStop().length;
    setState(() {
      _alunosNaVan += aqui;
      // Após finalizar, volta para o estado de tempo correto
      _estado = _calcularEstadoTempo();
    });
  }

  bool get _isUltimaParada => _paradaAtualIndex >= _paradas.length - 1;
  bool get _todosEmbarcaram => _alunosNaVan >= _activeStudents.length;

  // ─── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        ),
        backgroundColor: AppColors.orange,
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CabecalhoData(),
                  NotificationBadge(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificacaoTela(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFC3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.orange,
                backgroundColor: AppColors.navBackground,
              ),
            if (!_isLoading)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: switch (_estado) {
                    _EstadoMotorista.antesDoHorario =>
                      _buildCorpoAntesDoHorario(),
                    _EstadoMotorista.listaFechada =>
                      _buildCorpoListaFechada(),
                    _EstadoMotorista.emRota => _buildCorpoEmRota(),
                    _EstadoMotorista.aguardandoVolta =>
                      _buildCorpoAguardandoVolta(),
                    _EstadoMotorista.emRotaVolta => _buildCorpoEmRota(),
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── ANTES DO HORÁRIO LIMITE ──────────────────────────────────────────────────
  // Lista IDA em formação — alunos ainda podem confirmar/cancelar (RN01)

  Widget _buildCorpoAntesDoHorario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _buildBanner(
          texto:
              'Lista em formação — confirmações abertas até às $_deadlineFormatado',
          destaque: false,
        ),
        const SizedBox(height: 16),
        _buildCardAlunosConfirmados(_idaStudents),
        const SizedBox(height: 16),
        _buildCardsFinanceiros(),
        const Spacer(),
        // INICIAR desabilitado antes do prazo (RN01)
        AppOutlinedButton(
          label: 'INICIAR',
          borderColor: AppColors.inactiveIcon,
          onPressed: null,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── LISTA FECHADA ────────────────────────────────────────────────────────────
  // Prazo encerrado — lista IDA final, INICIAR habilitado

  Widget _buildCorpoListaFechada() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _buildBanner(
          texto: 'Lista fechada — pronto para iniciar a rota',
          destaque: true,
        ),
        const SizedBox(height: 16),
        _buildCardAlunosConfirmados(_idaStudents),
        const SizedBox(height: 16),
        _buildCardsFinanceiros(),
        const Spacer(),
        AppOutlinedButton(
          label: 'INICIAR',
          onPressed: _idaStudents.isEmpty
              ? null
              : () => _iniciarRota(isVolta: false),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── AGUARDANDO VOLTA ─────────────────────────────────────────────────────────
  // 20:01+ — mostra alunos esperados no retorno (RN05)

  Widget _buildCorpoAguardandoVolta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _buildBanner(
          texto: 'Turno da volta — alunos esperados no retorno',
          destaque: true,
        ),
        const SizedBox(height: 16),
        _buildCardAlunosConfirmados(_voltaStudents),
        const SizedBox(height: 16),
        _buildCardsFinanceiros(),
        const Spacer(),
        AppOutlinedButton(
          label: 'INICIAR VOLTA',
          onPressed: _voltaStudents.isEmpty
              ? null
              : () => _iniciarRota(isVolta: true),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── EM ROTA (IDA e VOLTA usam o mesmo layout) ────────────────────────────────
  // UC09 — motorista navega pelas paradas

  Widget _buildCorpoEmRota() {
    final paradaAtual =
        _paradas.isNotEmpty ? _paradas[_paradaAtualIndex] : 'Ponto';
    final studentsHere = _studentsAtCurrentStop();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Text(
          'Van na $paradaAtual',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ContadorBadge(
          atual: _alunosNaVan,
          total: _activeStudents.length,
        ),
        const SizedBox(height: 20),
        _buildCardAlunosConfirmados(studentsHere),
        const Spacer(),
        _buildBotaoNavegacao(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBotaoNavegacao() {
    if (!_isUltimaParada) {
      return AppOutlinedButton(
        label: 'IR PARA O PROXIMO PONTO',
        onPressed: _irParaProximoPonto,
      );
    }

    // Última parada: cinza até todos embarcarem, laranja quando completo (UC09)
    return AppOutlinedButton(
      label: 'Ir embora',
      borderColor:
          _todosEmbarcaram ? AppColors.orange : const Color(0xFF4A5568),
      onPressed: _finalizarRota,
    );
  }

  // ─── WIDGETS COMPARTILHADOS ───────────────────────────────────────────────────

  Widget _buildBanner({required String texto, required bool destaque}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: destaque
              ? AppColors.orange
              : AppColors.orange.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: destaque ? AppColors.orange : AppColors.white,
          fontSize: 13,
          fontWeight: destaque ? FontWeight.w600 : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCardAlunosConfirmados(List<TransportStudentSummary> students) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ALUNOS CONFIRMADOS',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (students.isEmpty)
            const Text(
              'Nenhum aluno confirmado ainda.',
              style: TextStyle(color: AppColors.textHint, fontSize: 14),
            )
          else
            ...students.map(_buildAlunoRow),
        ],
      ),
    );
  }

  Widget _buildAlunoRow(TransportStudentSummary student) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFD1D5DB),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            student.name,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // Cards financeiros — placeholder até RF06 ser implementado
  Widget _buildCardsFinanceiros() {
    return Row(
      children: [
        Expanded(child: _buildCardInfo('12', 'Pagamentos\nem Aberto')),
        const SizedBox(width: 12),
        Expanded(child: _buildCardInfo('2', 'Pagamentos\nPendentes')),
      ],
    );
  }

  Widget _buildCardInfo(String valor, String descricao) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            descricao,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

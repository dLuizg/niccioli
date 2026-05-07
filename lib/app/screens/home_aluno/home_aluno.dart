import 'dart:async';
import 'package:flutter/material.dart';
import 'package:niccioli/app/screens/notification/notification_screen.dart';
import 'package:niccioli/app/services/auth_service.dart';
import 'package:niccioli/app/services/transport_service.dart';
import 'package:niccioli/app/views/widgets/notification_badge.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/van/contador_badge.dart';
import '../../views/widgets/data_badge.dart';

// Modo da tela baseado no horário:
// antes        → 00:01 até 16:59 (confirmação de ida)
// intermediario → 17:00 até 20:00 (horário limite / não solicitado)
// depois       → 20:01 até 00:00 (check-in de volta)
enum _ModoHome { antes, intermediario, depois }

// Estados do fluxo de ida (modo antes)
enum _EstadoAntes {
  pendente, // Aguardando confirmação do aluno
  confirmado, // Aluno confirmou presença
  cancelando, // Dialog de cancelamento aberto
  naoSolicitado, // Aluno informou que não vai
  horarioLimite, // Prazo encerrado
}

// Estados do período intermediário (17:00–20:00)
enum _EstadoIntermediario {
  naoSolicitado, // Aluno não confirmou — pode ainda solicitar
  horarioLimite, // Prazo esgotado — apenas contato com motorista
}

// Estados do fluxo de volta (modo depois)
enum _EstadoDepois {
  aguardando, // Van ainda não chegou ao ponto
  vanChegou, // Van chegou — aguardando confirmação
  solicitandoOutroPonto, // Dialog: escolha do ponto alternativo
  confirmandoOutroPonto, // Dialog: confirmação do ponto escolhido
  finalizado, // Check-in de volta concluído
}

class HomeAluno extends StatefulWidget {
  const HomeAluno({super.key});

  @override
  State<HomeAluno> createState() => _HomeAlunoState();
}

class _HomeAlunoState extends State<HomeAluno> {
  // Modo atual — determinado pelo horário e atualizado automaticamente
  late _ModoHome _modo;

  // Estados internos de cada fluxo
  _EstadoAntes _estadoAntes = _EstadoAntes.pendente;
  _EstadoIntermediario _estadoIntermediario =
      _EstadoIntermediario.naoSolicitado;
  _EstadoDepois _estadoDepois = _EstadoDepois.aguardando;

  // Ponto alternativo selecionado no dialog de volta
  String _pontoSelecionado = '';

  // Dados da van — alimentados pelo sistema de contador do projeto
  final String _localVan = 'Van na Fazenda';
  final int _alunosAtuais = 1;
  final int _alunosTotal = 2;

  bool _isSavingPresence = false;
  String? _presenceMessage;

  // Timer que verifica a cada minuto se o modo deve mudar
  Timer? _timer;

  // Calcula o modo correto pelos minutos totais do dia:
  // 00:01–16:59 → antes   (1–1019 min)
  // 17:00–20:00 → intermediario (1020–1200 min)
  // 20:01–00:00 → depois  (>1200 min ou 0 = meia-noite)
  static _ModoHome _calcularModo() {
    final now = DateTime.now();
    final total = now.hour * 60 + now.minute;
    if (total == 0 || total > 1200) return _ModoHome.depois;
    if (total >= 1020) return _ModoHome.intermediario;
    return _ModoHome.antes;
  }

  // Saudação dinâmica baseada no horário
  String get _saudacao {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom Dia!';
    if (hour < 18) return 'Boa Tarde!';
    return 'Boa Noite!';
  }

  // Subtexto da saudação no estado pendente (modo antes)
  String get _subSaudacao {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Tenha um ótimo dia!';
    if (hour < 18) return 'Tenha uma ótima tarde!';
    return 'Tenha uma boa noite!';
  }

  @override
  void initState() {
    super.initState();
    _modo = _calcularModo();
    _loadTodayPresence();

    // Verifica a cada minuto se o modo deve mudar automaticamente
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final novoModo = _calcularModo();
      if (novoModo != _modo) {
        setState(() {
          _modo = novoModo;
          // Reinicia estados internos ao trocar de modo
          _estadoAntes = _EstadoAntes.pendente;
          _estadoIntermediario = _EstadoIntermediario.naoSolicitado;
          _estadoDepois = _EstadoDepois.aguardando;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancela o timer ao sair da tela para evitar memory leak
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTodayPresence() async {
    try {
      final response = await TransportService.instance
          .loadTodayPresenceResponse();
      if (!mounted) {
        return;
      }

      setState(() {
        switch (response.outboundStatus) {
          case 'confirmed':
            _estadoAntes = _EstadoAntes.confirmado;
            break;
          case 'notGoing':
            _estadoAntes = _EstadoAntes.naoSolicitado;
            break;
        }

        switch (response.returnStatus) {
          case 'released':
            _estadoDepois = _EstadoDepois.vanChegou;
            break;
          case 'inVan':
          case 'notReturning':
          case 'alternatePickup':
            _estadoDepois = _EstadoDepois.finalizado;
            break;
        }

        _pontoSelecionado = response.alternatePickupPoint ?? '';
      });
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() {
          _presenceMessage = error.message;
        });
      }
    }
  }

  Future<void> _saveTodayPresence({
    String? outboundStatus,
    String? returnStatus,
    String? alternatePickupPoint,
    required VoidCallback applyLocalState,
  }) async {
    if (_isSavingPresence) {
      return;
    }

    setState(() {
      _isSavingPresence = true;
      _presenceMessage = null;
      applyLocalState();
    });

    try {
      await TransportService.instance.updateTodayPresenceResponse(
        outboundStatus: outboundStatus,
        returnStatus: returnStatus,
        alternatePickupPoint: alternatePickupPoint,
      );
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() {
          _presenceMessage = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPresence = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildMainContent(),
          // Overlay de cancelamento — modo antes
          if (_modo == _ModoHome.antes &&
              _estadoAntes == _EstadoAntes.cancelando)
            _buildOverlayCancelamento(),
          // Dialogs — modo depois
          if (_modo == _ModoHome.depois &&
              _estadoDepois == _EstadoDepois.solicitandoOutroPonto)
            _buildDialogOutroPonto(),
          if (_modo == _ModoHome.depois &&
              _estadoDepois == _EstadoDepois.confirmandoOutroPonto)
            _buildDialogConfirmacao(),
        ],
      ),
    );
  }

  // ─── ESTRUTURA PRINCIPAL ───────────────────────────────────────────────────

  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: CabecalhoData à esquerda, sino à direita
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CabecalhoData(),
                NotificationBadge(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificacaoTela()),
                  ),
                ),
              ],
            ),
          ),
          // Corpo central — delega ao modo ativo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  if (_presenceMessage != null) ...[
                    Text(
                      _presenceMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFC3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_isSavingPresence)
                    const LinearProgressIndicator(
                      minHeight: 2,
                      color: AppColors.orange,
                      backgroundColor: AppColors.navBackground,
                    ),
                  Expanded(
                    child: switch (_modo) {
                      _ModoHome.antes => _buildCorpoAntes(),
                      _ModoHome.intermediario => _buildCorpoIntermediario(),
                      _ModoHome.depois => _buildCorpoDepois(),
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MODO ANTES (00:01 – 16:59) ───────────────────────────────────────────

  Widget _buildCorpoAntes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        Text(
          _saudacao,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        _buildSubtituloAntes(),
        const Spacer(flex: 3),
        _buildAcaoAntes(),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildSubtituloAntes() {
    switch (_estadoAntes) {
      case _EstadoAntes.pendente:
        return Text(
          _subSaudacao,
          style: const TextStyle(color: AppColors.white, fontSize: 16),
          textAlign: TextAlign.center,
        );
      case _EstadoAntes.confirmado:
      case _EstadoAntes.cancelando:
        return const Text(
          'Confirmado',
          style: TextStyle(color: AppColors.white, fontSize: 22),
          textAlign: TextAlign.center,
        );
      case _EstadoAntes.naoSolicitado:
        return const Text(
          'Não solicitado',
          style: TextStyle(color: AppColors.white, fontSize: 22),
          textAlign: TextAlign.center,
        );
      case _EstadoAntes.horarioLimite:
        return const Text(
          'Horário limite atingido\nEntre em contato com o motorista',
          style: TextStyle(color: AppColors.white, fontSize: 18),
          textAlign: TextAlign.center,
        );
    }
  }

  Widget _buildAcaoAntes() {
    switch (_estadoAntes) {
      case _EstadoAntes.pendente:
        return Column(
          children: [
            const Text(
              'Você vai hoje?',
              style: TextStyle(color: AppColors.white, fontSize: 20),
            ),
            const SizedBox(height: 16),
            AppDualOutlinedButton(
              label1: 'CONFIRMAR',
              onPressed1: () => _saveTodayPresence(
                outboundStatus: 'confirmed',
                applyLocalState: () => _estadoAntes = _EstadoAntes.confirmado,
              ),
              label2: 'NÃO VOU',
              onPressed2: () => _saveTodayPresence(
                outboundStatus: 'notGoing',
                applyLocalState: () =>
                    _estadoAntes = _EstadoAntes.naoSolicitado,
              ),
            ),
          ],
        );
      case _EstadoAntes.confirmado:
      case _EstadoAntes.cancelando:
        return AppOutlinedButton(
          label: 'CANCELAR',
          onPressed: () =>
              setState(() => _estadoAntes = _EstadoAntes.cancelando),
        );
      case _EstadoAntes.naoSolicitado:
        return AppOutlinedButton(
          label: 'Solicitar',
          onPressed: () => _saveTodayPresence(
            outboundStatus: 'confirmed',
            applyLocalState: () => _estadoAntes = _EstadoAntes.confirmado,
          ),
        );
      case _EstadoAntes.horarioLimite:
        return AppOutlinedButton(label: 'Entrar em contato', onPressed: () {});
    }
  }

  Widget _buildOverlayCancelamento() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.dialogOrange,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tem certeza que deseja cancelar?',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Se você cancelar, ficará marcado direto como "Não Solicitado"',
                style: TextStyle(color: AppColors.textDark, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              AppDualFilledButton(
                label1: 'Entendo,\nquero Cancelar!',
                onPressed1: () => _saveTodayPresence(
                  outboundStatus: 'notGoing',
                  applyLocalState: () =>
                      _estadoAntes = _EstadoAntes.naoSolicitado,
                ),
                label2: 'Quero Manter o\ntransporte!',
                onPressed2: () => _saveTodayPresence(
                  outboundStatus: 'confirmed',
                  applyLocalState: () => _estadoAntes = _EstadoAntes.confirmado,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── MODO INTERMEDIÁRIO (17:00 – 20:00) ───────────────────────────────────

  Widget _buildCorpoIntermediario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        // Saudação — período sempre vespertino
        const Text(
          'Boa Tarde!',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        _buildSubtituloIntermediario(),
        const Spacer(flex: 3),
        _buildAcaoIntermediario(),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildSubtituloIntermediario() {
    switch (_estadoIntermediario) {
      case _EstadoIntermediario.naoSolicitado:
        return const Text(
          'Não solicitado',
          style: TextStyle(color: AppColors.white, fontSize: 22),
          textAlign: TextAlign.center,
        );
      case _EstadoIntermediario.horarioLimite:
        // Prazo encerrado — orientar o aluno a contatar o motorista
        return const Text(
          'Horário limite atingido entre\nem contato com o motorista',
          style: TextStyle(color: AppColors.white, fontSize: 18),
          textAlign: TextAlign.center,
        );
    }
  }

  Widget _buildAcaoIntermediario() {
    switch (_estadoIntermediario) {
      case _EstadoIntermediario.naoSolicitado:
        // Aluno pode ainda solicitar transporte antes do prazo final
        return AppOutlinedButton(
          label: 'Solicitar',
          onPressed: () => _saveTodayPresence(
            outboundStatus: 'confirmed',
            applyLocalState: () =>
                _estadoIntermediario = _EstadoIntermediario.horarioLimite,
          ),
        );
      case _EstadoIntermediario.horarioLimite:
        // Prazo esgotado — único caminho é contato direto com motorista
        return AppOutlinedButton(label: 'Entrar em contato', onPressed: () {});
    }
  }

  // ─── MODO DEPOIS (20:01 – 00:00) ──────────────────────────────────────────

  Widget _buildCorpoDepois() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        // Saudação fixa — tela ativa somente no período noturno
        const Text(
          'Boa Noite!',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Faça seu check-in',
          style: TextStyle(color: AppColors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const Spacer(flex: 1),
        // Localização e contador ocultos após finalizar check-in
        if (_estadoDepois != _EstadoDepois.finalizado) ...[
          Text(
            _localVan,
            style: const TextStyle(color: AppColors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ContadorBadge(atual: _alunosAtuais, total: _alunosTotal),
        ],
        const Spacer(flex: 2),
        _buildAcaoDepois(),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildAcaoDepois() {
    switch (_estadoDepois) {
      case _EstadoDepois.aguardando:
        // Van ainda a caminho — aluno confirma liberação da faculdade
        return Column(
          children: [
            const Text(
              'Aguarde a chegada da van no\nseu local de embarque',
              style: TextStyle(color: AppColors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppOutlinedButton(
              label: 'Já Fui Liberado(a)',
              onPressed: () => _saveTodayPresence(
                returnStatus: 'released',
                applyLocalState: () => _estadoDepois = _EstadoDepois.vanChegou,
              ),
            ),
            const SizedBox(height: 20),
            _buildLinksDepois(),
          ],
        );
      case _EstadoDepois.vanChegou:
      case _EstadoDepois.solicitandoOutroPonto:
      case _EstadoDepois.confirmandoOutroPonto:
        // Van chegou — aluno confirma presença física na van
        return Column(
          children: [
            const Text(
              'Você está na van?',
              style: TextStyle(color: AppColors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppOutlinedButton(
              label: 'SIM, ESTOU',
              onPressed: () => _saveTodayPresence(
                returnStatus: 'inVan',
                applyLocalState: () => _estadoDepois = _EstadoDepois.finalizado,
              ),
            ),
            const SizedBox(height: 20),
            _buildLinksDepois(),
          ],
        );
      case _EstadoDepois.finalizado:
        return const Text(
          'Obrigado por Hoje, até amanhã!\nFaça uma boa viagem!',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        );
    }
  }

  Widget _buildLinksDepois() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _saveTodayPresence(
            returnStatus: 'notReturning',
            applyLocalState: () => _estadoDepois = _EstadoDepois.finalizado,
          ),
          child: const Text(
            'Não vou voltar',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(
            () => _estadoDepois = _EstadoDepois.solicitandoOutroPonto,
          ),
          child: const Text(
            'Vou pegar a van em outro lugar',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
      ],
    );
  }

  // Primeiro dialog: escolha do ponto alternativo de embarque
  Widget _buildDialogOutroPonto() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.dialogOrange,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Solicitar Entrar no van em outro Ponto?',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Escolha qual ponto futuro você entrará no van',
                style: TextStyle(color: AppColors.textDark, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppDualFilledButton(
                label1: 'Unifeob',
                onPressed1: () => setState(() {
                  _pontoSelecionado = 'Unifeob';
                  _estadoDepois = _EstadoDepois.confirmandoOutroPonto;
                }),
                label2: 'Unifae',
                onPressed2: () => setState(() {
                  _pontoSelecionado = 'Unifae';
                  _estadoDepois = _EstadoDepois.confirmandoOutroPonto;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Segundo dialog: confirmação do ponto alternativo escolhido
  Widget _buildDialogConfirmacao() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.dialogOrange,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Solicitar Entrar no van em outro Ponto?',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Tem certeza que vai pegar a van no ponto da $_pontoSelecionado?',
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppFilledButton(
                label:
                    'Sim, vou pegar o van no ponto ${_pontoSelecionado.toLowerCase()}',
                onPressed: () => _saveTodayPresence(
                  returnStatus: 'alternatePickup',
                  alternatePickupPoint: _pontoSelecionado,
                  applyLocalState: () =>
                      _estadoDepois = _EstadoDepois.finalizado,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

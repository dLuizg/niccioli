import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_bottom_nav.dart';

// Estados possíveis da tela — controlam greeting, subtítulo e botões exibidos
enum _HomeState { pendente, confirmado, cancelando, naoSolicitado, horarioLimite }

class HomeAlunoAntes extends StatefulWidget {
  const HomeAlunoAntes({super.key});

  @override
  State<HomeAlunoAntes> createState() => _HomeAlunoAntesState();
}

class _HomeAlunoAntesState extends State<HomeAlunoAntes> {
  // Estado inicial: aluno ainda não confirmou presença
  _HomeState _state = _HomeState.pendente;

  // Índice da aba ativa na bottom nav (0 = Home)
  int _navIndex = 0;

  // Strings de data formatadas após inicialização do locale
  String _diaSemana = '';
  String _dataNumerica = '';

  @override
  void initState() {
    super.initState();
    // Garante que o locale pt_BR está disponível independente do main()
    initializeDateFormatting('pt_BR', null).then((_) {
      final agora = DateTime.now();
      final rawDia = DateFormat('EEEE', 'pt_BR').format(agora);
      setState(() {
        _diaSemana = rawDia[0].toUpperCase() + rawDia.substring(1);
        _dataNumerica = DateFormat('dd/MM/yyyy', 'pt_BR').format(agora);
      });
    });
  }

  // Saudação principal baseada no horário do dispositivo
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom Dia!';
    if (hour < 18) return 'Boa Tarde!';
    return 'Boa Noite!';
  }

  // Subtexto complementar exibido apenas no estado pendente
  String get _subGreetingPendente {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Tenha um ótimo dia!';
    if (hour < 18) return 'Tenha uma ótima tarde!';
    return 'Tenha uma boa noite!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Conteúdo principal sempre presente na base da stack
          _buildMainContent(),
          // Overlay de confirmação de cancelamento — só renderiza quando necessário
          if (_state == _HomeState.cancelando) _buildCancelOverlay(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _navIndex,
        onItemTapped: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  // Estrutura principal: header (data + sino) + área de conteúdo central
  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: data/dia à esquerda, sino de notificação à direita
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _diaSemana,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _dataNumerica,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                _buildNotificationBell(),
              ],
            ),
          ),
          // Área central: saudação no terço superior, ação no terço inferior
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Text(
                    _greeting,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Subtítulo muda conforme o estado atual
                  _buildSubTitle(),
                  const Spacer(flex: 3),
                  // Seção de ação muda conforme o estado atual
                  _buildActionSection(),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ícone de sino com borda circular — abre tela de notificações
  Widget _buildNotificationBell() {
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

  // Subtítulo abaixo da saudação — reflete o status atual da presença
  Widget _buildSubTitle() {
    switch (_state) {
      case _HomeState.pendente:
        // Mensagem de boas-vindas enquanto o aluno ainda não confirmou
        return Text(
          _subGreetingPendente,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        );
      case _HomeState.confirmado:
      case _HomeState.cancelando:
        // Cancelando mantém o subtítulo de confirmado (estado visível atrás do overlay)
        return const Text(
          'Confirmado',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 22,
          ),
          textAlign: TextAlign.center,
        );
      case _HomeState.naoSolicitado:
        return const Text(
          'Não solicitado',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 22,
          ),
          textAlign: TextAlign.center,
        );
      case _HomeState.horarioLimite:
        // Exibido quando o prazo para solicitar/confirmar foi encerrado
        return const Text(
          'Horário limite atingido\nEntre em contato com o motorista',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        );
    }
  }

  // Seção de ação: pergunta + botões variam conforme o estado
  Widget _buildActionSection() {
    switch (_state) {
      case _HomeState.pendente:
        // Aluno escolhe entre confirmar presença ou informar ausência
        return Column(
          children: [
            const Text(
              'Você vai hoje?',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            AppDualOutlinedButton(
              label1: 'CONFIRMAR',
              onPressed1: () => setState(() => _state = _HomeState.confirmado),
              label2: 'NÃO VOU',
              onPressed2: () => setState(() => _state = _HomeState.naoSolicitado),
            ),
          ],
        );
      case _HomeState.confirmado:
      case _HomeState.cancelando:
        // Cancelando mantém o botão CANCELAR visível atrás do overlay semitransparente
        return AppOutlinedButton(
          label: 'CANCELAR',
          onPressed: () => setState(() => _state = _HomeState.cancelando),
        );
      case _HomeState.naoSolicitado:
        // Permite ao aluno solicitar transporte após ter optado por não ir
        return AppOutlinedButton(
          label: 'Solicitar',
          onPressed: () => setState(() => _state = _HomeState.pendente),
        );
      case _HomeState.horarioLimite:
        // Horário encerrado — única ação disponível é contato direto com o motorista
        return AppFilledButton(
          label: 'Entrar em contato',
          onPressed: () {},
        );
    }
  }

  // Overlay de confirmação de cancelamento — cobre toda a tela sobre o conteúdo
  Widget _buildCancelOverlay() {
    return Container(
      // Fundo semitransparente para manter o contexto visual da tela abaixo
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
              // Aviso sobre a consequência do cancelamento
              const Text(
                'Se você cancelar, ficará marcado direto como "Não Solicitado"',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              AppDualFilledButton(
                label1: 'Entendo,\nquero Cancelar!',
                onPressed1: () => setState(() => _state = _HomeState.naoSolicitado),
                label2: 'Quero Manter o\ntransporte!',
                onPressed2: () => setState(() => _state = _HomeState.confirmado),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

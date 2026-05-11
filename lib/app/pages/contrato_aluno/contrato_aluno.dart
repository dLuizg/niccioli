import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
// ignore: unused_import — importado para uso futuro na tela de contrato
import '../../widgets/app_button.dart';
import '../../widgets/contrato/exportar_contrato.dart';
import '../../views/widgets/status_badge.dart';

// Vista ativa dentro da tela de contratos
enum _Vista { lista, detalhe }

// Status possíveis de um contrato
enum _StatusContrato { aguardando, assinado, expirado }

// Modelo de dados de um contrato (mock)
class _Contrato {
  final String titulo;
  final String rota;
  final String dataEmissao;
  final _StatusContrato status;

  const _Contrato({
    required this.titulo,
    required this.rota,
    required this.dataEmissao,
    required this.status,
  });
}

class ContratoAluno extends StatefulWidget {
  const ContratoAluno({super.key});

  @override
  State<ContratoAluno> createState() => _ContratoAlunoState();
}

class _ContratoAlunoState extends State<ContratoAluno> {
  _Vista _vista = _Vista.lista;
  int _contratoSelecionado = 0;

  // Dados mock — serão substituídos pela integração com backend
  final List<_Contrato> _contratos = const [
    _Contrato(
      titulo: 'Contrato de Transporte Escolar 2025',
      rota: 'Facul. Est. Jair Messias * Rota SJ Boa Vista',
      dataEmissao: 'Emitido: 15 jan 2025',
      status: _StatusContrato.aguardando,
    ),
    _Contrato(
      titulo: 'Contrato de Transporte Escolar 2024',
      rota: 'Facul. Est. Jair Messias * Rota SJ Boa Vista',
      dataEmissao: 'Emitido: 15 jan 2025',
      status: _StatusContrato.assinado,
    ),
    _Contrato(
      titulo: 'Contrato de Transporte Escolar 2023',
      rota: 'Facul. Est. Jair Messias * Rota SJ Boa Vista',
      dataEmissao: 'Emitido: 15 jan 2025',
      status: _StatusContrato.expirado,
    ),
  ];

  // Contadores calculados a partir dos dados
  int get _totalAguardando =>
      _contratos.where((c) => c.status == _StatusContrato.aguardando).length;
  int get _totalAssinados =>
      _contratos.where((c) => c.status == _StatusContrato.assinado).length;
  int get _total => _contratos.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _vista == _Vista.lista ? _buildLista() : _buildDetalhe(),
    );
  }

  // ─── VISTA: LISTA DE CONTRATOS ────────────────────────────────────────────

  Widget _buildLista() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com nome do aluno e sino
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Olá, Jair',
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
            const SizedBox(height: 24),
            // Cards de estatísticas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('$_totalAguardando', 'Aguardando\nAssinatura'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard('$_totalAssinados', 'Assinados'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard('$_total', 'Total de\nContratos'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Seção: aguardando assinatura
            if (_totalAguardando > 0) ...[
              _buildSectionLabel('AGUARDANDO ASSINATURA'),
              const SizedBox(height: 12),
              ..._contratos
                  .where((c) => c.status == _StatusContrato.aguardando)
                  .map((c) => _buildContratoCard(c)),
              const SizedBox(height: 24),
            ],
            // Seção: assinados e expirados
            if (_totalAssinados > 0 ||
                _contratos.any((c) => c.status == _StatusContrato.expirado)) ...[
              _buildSectionLabel('ASSINADOS'),
              const SizedBox(height: 12),
              ..._contratos
                  .where((c) => c.status != _StatusContrato.aguardando)
                  .map((c) => _buildContratoCard(c)),
            ],
          ],
        ),
      ),
    );
  }

  // Card de estatística individual
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

  // Label de seção em caixa alta
  Widget _buildSectionLabel(String texto) {
    return Text(
      texto,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  // Card de contrato na lista
  Widget _buildContratoCard(_Contrato contrato) {
    return GestureDetector(
      onTap: () {
        final idx = _contratos.indexOf(contrato);
        setState(() {
          _contratoSelecionado = idx;
          _vista = _Vista.detalhe;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1F3C),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Ícone do contrato
            _buildIconeContrato(contrato.status),
            const SizedBox(width: 12),
            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contrato.titulo,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contrato.rota,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contrato.dataEmissao,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Badge / botão de status
            _buildStatusContrato(contrato.status),
          ],
        ),
      ),
    );
  }

  // Ícone colorido à esquerda do card
  Widget _buildIconeContrato(_StatusContrato status) {
    final isAguardando = status == _StatusContrato.aguardando;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isAguardando
            ? AppColors.orange.withValues(alpha: 0.15)
            : const Color(0xFF1D5E52),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isAguardando ? Icons.article_outlined : Icons.check_circle_outline,
        color: isAguardando ? AppColors.orange : const Color(0xFF42E21E),
        size: 22,
      ),
    );
  }

  // Badge de status à direita do card
  Widget _buildStatusContrato(_StatusContrato status) {
    switch (status) {
      case _StatusContrato.aguardando:
        // Botão "Assinar" laranja — ação de assinatura pendente
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.orange, width: 1),
          ),
          child: const Text(
            '✦ Assinar',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case _StatusContrato.assinado:
        return StatusBadge(
          status: StatusBadgeType.assinado,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          textStyle: const TextStyle(fontSize: 12),
        );
      case _StatusContrato.expirado:
        return StatusBadge(
          status: StatusBadgeType.vencido,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          textStyle: const TextStyle(fontSize: 12),
          showDot: false,
        );
    }
  }

  // ─── VISTA: DETALHE DO CONTRATO ───────────────────────────────────────────

  Widget _buildDetalhe() {
    final contrato = _contratos[_contratoSelecionado];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com botão de voltar e sino
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _vista = _Vista.lista),
                  child: const Icon(Icons.arrow_back_ios,
                      color: AppColors.white, size: 20),
                ),
                _buildSino(),
              ],
            ),
            const SizedBox(height: 20),
            // Título e status do contrato
            const Text(
              'Contrato de Transporte',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Badge "Ativo"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D5E52),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF42E21E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Ativo',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Vigência 15 jan 2025 - 15 jun 2025',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Card: Dados do contrato
            _buildCardDados(),
            const SizedBox(height: 16),
            // Card: Assinatura e documentação
            _buildCardAssinatura(contrato),
          ],
        ),
      ),
    );
  }

  // Card com os dados do contrato
  Widget _buildCardDados() {
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
          _buildCardSectionLabel('DADOS DO CONTRATO'),
          const SizedBox(height: 16),
          // Linha 1: Estudante + RA
          Row(
            children: [
              Expanded(child: _buildDadoItem('ESTUDANTE', 'Jair Messias Bolsonaro')),
              Expanded(child: _buildDadoItem('RA', '200035-00')),
            ],
          ),
          const SizedBox(height: 14),
          // Linha 2: Instituição + Período
          Row(
            children: [
              Expanded(child: _buildDadoItem('INSTITUIÇÃO', 'UNIFEOB')),
              Expanded(child: _buildDadoItem('PERÍODO', 'Noturno - 19h00')),
            ],
          ),
          const SizedBox(height: 14),
          // Linha 3: Rota + Motorista + Mensalidade
          Row(
            children: [
              Expanded(child: _buildDadoItem('ROTA', 'Mogi Guaçu - Unifeob')),
              Expanded(child: _buildDadoItem('MOTORISTA', 'Niccioli')),
              Expanded(child: _buildDadoItem('MENSALIDADE', 'R\$ 309,00')),
            ],
          ),
        ],
      ),
    );
  }

  // Item individual de dado (label + valor)
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

  // Card de assinatura e documentação
  Widget _buildCardAssinatura(_Contrato contrato) {
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
          _buildCardSectionLabel('ASSINATURA E DOCUMENTAÇÃO'),
          const SizedBox(height: 20),
          // Passo 1: Exportar contrato em PDF (já concluído)
          _buildPassoExportarPDF(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white12, thickness: 1),
          ),
          // Passos 2 e 3: Assinar Gov.br + Anexar (widget reutilizável)
          ExportarContrato(
            onArquivoAnexado: (caminho) {
              // Caminho do PDF assinado recebido para envio ao motorista
            },
          ),
        ],
      ),
    );
  }

  // Passo 1 — Exportar PDF (estado concluído)
  Widget _buildPassoExportarPDF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícone de concluído
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF1D5E52),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Color(0xFF42E21E),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Exportar contrato em PDF',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 52),
          child: Text(
            'Baixe o documento para assinar digitalmente',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Botões de exportação
        Padding(
          padding: const EdgeInsets.only(left: 52),
          child: Row(
            children: [
              // Badge de data de exportação
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF091525),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Exportado * 02 jan 2026',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Botão de baixar novamente
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2A4A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: const Text(
                    'Baixar novamente',
                    style: TextStyle(color: AppColors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Label de seção dentro dos cards
  Widget _buildCardSectionLabel(String texto) {
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

  // Sino de notificação reutilizado nos dois headers
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
}

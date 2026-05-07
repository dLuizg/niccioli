import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_colors.dart';

// Componente de assinatura e anexo do contrato via Gov.br.
// Uso: ExportarContrato(onArquivoAnexado: (path) { ... })
class ExportarContrato extends StatefulWidget {
  // Callback chamado quando o aluno seleciona o arquivo PDF assinado
  final void Function(String caminhoArquivo)? onArquivoAnexado;

  const ExportarContrato({super.key, this.onArquivoAnexado});

  @override
  State<ExportarContrato> createState() => _ExportarContratoState();
}

class _ExportarContratoState extends State<ExportarContrato> {
  // Nome do arquivo selecionado — null enquanto nenhum arquivo for escolhido
  String? _nomeArquivo;

  // Abre o assinador digital Gov.br no navegador padrão do dispositivo
  Future<void> _abrirGovBr() async {
    final uri = Uri.parse('https://assinador.iti.br');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Abre o seletor de arquivos filtrado para PDF
  Future<void> _selecionarArquivo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (resultado != null && resultado.files.single.path != null) {
      final arquivo = resultado.files.single;
      setState(() => _nomeArquivo = arquivo.name);
      widget.onArquivoAnexado?.call(arquivo.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPassoGovBr(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Divider(color: Colors.white12, thickness: 1),
        ),
        _buildPassoAnexar(),
      ],
    );
  }

  // ─── PASSO 2: Assinar com Gov.br ──────────────────────────────────────────

  Widget _buildPassoGovBr() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Número do passo + título
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNumeroPasso(2),
            const SizedBox(width: 16),
            const Flexible(
              child: Text(
                'Assinar com Gov.br',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Descrição do passo
        const Padding(
          padding: EdgeInsets.only(left: 56),
          child: Text(
            'Acesse a plataforma de assinatura digital do governo federal.\n'
            'Faça login com sua conta Gov.br e assine o PDF exportado no passo anterior.',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: 24),
        // Botão Gov.br
        Padding(
          padding: const EdgeInsets.only(left: 56),
          child: _buildBotaoGovBr(),
        ),
      ],
    );
  }

  // Botão estilizado com label "gov.br" à esquerda e texto à direita
  Widget _buildBotaoGovBr() {
    return GestureDetector(
      onTap: _abrirGovBr,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B31),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seção "gov.br" — fundo levemente mais escuro
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF091525),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: const Text(
                'gov.br',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Seção "Abrir assinador digital"
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                'Abrir assinador\ndigital',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PASSO 3: Anexar contrato assinado ────────────────────────────────────

  Widget _buildPassoAnexar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Número do passo + título
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNumeroPasso(3),
            const SizedBox(width: 16),
            const Flexible(
              child: Text(
                'Anexar contrato assinado',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Descrição do passo com destaque no .pdf
        Padding(
          padding: const EdgeInsets.only(left: 56),
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'Após assinar no Gov.br, faça o upload do arquivo '),
                TextSpan(
                  text: '.pdf',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: ' com a assinatura digital'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Zona de upload
        GestureDetector(
          onTap: _selecionarArquivo,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1F3C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _nomeArquivo == null
                ? _buildZonaUploadVazia()
                : _buildZonaUploadPreenchida(),
          ),
        ),
      ],
    );
  }

  // Estado inicial da zona — sem arquivo selecionado
  Widget _buildZonaUploadVazia() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícone de upload em círculo
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white38, width: 2),
          ),
          child: const Icon(
            Icons.arrow_upward_rounded,
            color: Colors.white38,
            size: 26,
          ),
        ),
        const SizedBox(height: 16),
        // Texto clicável + instrução
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(fontSize: 15, height: 1.4),
            children: [
              TextSpan(
                text: 'Selecione arquivo',
                style: TextStyle(
                  color: Color(0xFF4A90D9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: ' ou arraste aqui',
                style: TextStyle(color: AppColors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Estado após seleção — exibe nome do arquivo com ícone de PDF
  Widget _buildZonaUploadPreenchida() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.picture_as_pdf, color: AppColors.orange, size: 28),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            _nomeArquivo!,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        // Botão para trocar o arquivo selecionado
        GestureDetector(
          onTap: _selecionarArquivo,
          child: const Icon(Icons.refresh, color: Colors.white54, size: 20),
        ),
      ],
    );
  }

  // Badge circular com o número do passo
  Widget _buildNumeroPasso(int numero) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF091525),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$numero',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

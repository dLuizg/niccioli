import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:niccioli/app/models/contract.dart';
import 'package:niccioli/app/services/contract_service.dart';
import 'package:niccioli/app/theme/app_colors.dart';
import 'package:niccioli/app/widgets/app_button.dart';
import 'package:niccioli/app/widgets/app_input_field.dart';

class ContractAttachScreen extends StatefulWidget {
  const ContractAttachScreen({
    super.key,
    required this.transportId,
    required this.studentId,
    required this.studentName,
    required this.driverUid,
  });

  final String transportId;
  final String studentId;
  final String studentName;
  final String driverUid;

  @override
  State<ContractAttachScreen> createState() => _ContractAttachScreenState();
}

class _ContractAttachScreenState extends State<ContractAttachScreen> {
  final _formKey = GlobalKey<FormState>();

  final _endDateCtrl = TextEditingController();
  final _monthlyValueCtrl = TextEditingController();

  DateTime? _endDate;
  PlatformFile? _selectedFile;
  bool _isSaving = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _endDateCtrl.dispose();
    _monthlyValueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                const Text(
                  'Anexar Contrato',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.studentName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                if (_isSaving) ...[
                  _buildProgressIndicator(),
                  const SizedBox(height: 16),
                ],
                _buildPdfCard(),
                const SizedBox(height: 12),
                _buildDadosCard(),
                const SizedBox(height: 24),
                AppFilledButton(
                  label: _isSaving ? 'Enviando...' : 'Enviar Contrato',
                  onPressed: _isSaving ? null : _save,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enviando PDF... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: _uploadProgress > 0 ? _uploadProgress : null,
          backgroundColor: const Color(0xFF0D1F3C),
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildPdfCard() {
    final hasFile = _selectedFile != null;
    return GestureDetector(
      onTap: _pickPdf,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1F3C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile
                ? AppColors.orange.withValues(alpha: 0.5)
                : Colors.white12,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.orange.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasFile ? Icons.picture_as_pdf : Icons.upload_file_outlined,
                color: hasFile ? AppColors.orange : Colors.white38,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile ? _selectedFile!.name : 'Selecionar PDF do contrato',
                    style: TextStyle(
                      color: hasFile ? AppColors.white : Colors.white54,
                      fontSize: 14,
                      fontWeight:
                          hasFile ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasFile) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB  •  Toque para trocar',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      'Apenas arquivos .pdf',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDadosCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('DADOS DO CONTRATO'),
          const SizedBox(height: 16),
          _buildDateField(
            hint: 'Data de vencimento',
            controller: _endDateCtrl,
          ),
          const SizedBox(height: 12),
          AppTextField(
            hintText: 'Mensalidade (R\$)',
            controller: _monthlyValueCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final cleaned = v?.trim().replaceAll(',', '.') ?? '';
              if (cleaned.isEmpty) return 'Informe a mensalidade';
              if (double.tryParse(cleaned) == null) return 'Valor inválido';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String hint,
    required TextEditingController controller,
  }) {
    return GestureDetector(
      onTap: _pickEndDate,
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          validator: (v) =>
              (v?.trim().isEmpty ?? true) ? 'Selecione uma data' : null,
          style: const TextStyle(color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textHint),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            suffixIcon: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textHint,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String texto) {
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

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now.add(const Duration(days: 180)),
      firstDate: now,
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.orange,
            onPrimary: Colors.white,
            surface: Color(0xFF0D1F3C),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _endDate = picked;
      _endDateCtrl.text = _formatDate(picked);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedFile == null) {
      _showError('Selecione o arquivo PDF do contrato.');
      return;
    }
    if (_selectedFile!.bytes == null) {
      _showError('Não foi possível ler o arquivo. Tente novamente.');
      return;
    }
    if (_endDate == null) {
      _showError('Selecione a data de vencimento.');
      return;
    }

    final value = double.tryParse(
      _monthlyValueCtrl.text.trim().replaceAll(',', '.'),
    );
    if (value == null) {
      _showError('Valor da mensalidade inválido.');
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadProgress = 0;
    });

    try {
      final contractId = ContractService.instance.generateId();

      final fileUrl = await ContractService.instance.uploadOriginalPdf(
        driverUid: widget.driverUid,
        studentId: widget.studentId,
        contractId: contractId,
        bytes: _selectedFile!.bytes!,
      );

      setState(() => _uploadProgress = 1.0);

      final now = DateTime.now();
      final contract = Contract(
        id: contractId,
        fileName: _selectedFile!.name,
        fileUrl: fileUrl,
        startDate: now,
        endDate: _endDate!,
        monthlyValue: value,
        paymentDay: 1,
        observations: null,
        status: ContractStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      await ContractService.instance.createContract(
        widget.transportId,
        widget.studentId,
        contract,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contrato enviado com sucesso!'),
            backgroundColor: Color(0xFF1D5E52),
          ),
        );
        Navigator.pop(context, true);
      }
    } on ContractFailure catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _uploadProgress = 0;
        });
        _showError(e.message);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF6A3242),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}

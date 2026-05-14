import 'package:flutter/material.dart';
import 'package:niccioli/app/models/contract.dart';
import 'package:niccioli/app/pages/contrato_motorista/contract_attach_screen.dart';
import 'package:niccioli/app/pages/contrato_motorista/contract_detail_screen.dart';
import 'package:niccioli/app/services/contract_service.dart';
import 'package:niccioli/app/theme/app_colors.dart';
import 'package:niccioli/app/views/widgets/status_badge.dart';

class ContratoListScreen extends StatefulWidget {
  const ContratoListScreen({
    super.key,
    required this.transportId,
    required this.studentId,
    required this.studentName,
    required this.driverUid,
    this.filterYear,
  });

  final String transportId;
  final String studentId;
  final String studentName;
  final String driverUid;
  final int? filterYear;

  @override
  State<ContratoListScreen> createState() => _ContratoListScreenState();
}

class _ContratoListScreenState extends State<ContratoListScreen> {
  ContractStatus? _activeFilter;
  List<Contract> _contracts = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final contracts = await ContractService.instance.listContracts(
        widget.transportId,
        widget.studentId,
      );
      if (mounted) {
        setState(() {
          _contracts = contracts;
          _isLoading = false;
        });
      }
    } on ContractFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    }
  }

  List<Contract> get _filtered {
    var list = _contracts;
    if (_activeFilter != null) {
      list = list.where((c) => c.status == _activeFilter).toList();
    }
    if (widget.filterYear != null) {
      list = list.where((c) {
        return c.startDate.year <= widget.filterYear! &&
            c.endDate.year >= widget.filterYear!;
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orange,
        onPressed: _openAttachScreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilterChips(),
            const Divider(color: Colors.white12, thickness: 1, height: 1),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Contratos de ${widget.studentName}',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildSino(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final options = <ContractStatus?>[
      null,
      ContractStatus.approved,
      ContractStatus.pending,
      ContractStatus.cancelled,
    ];
    final labels = ['Todos', 'Aprovados', 'Pendentes', 'Cancelados'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(options.length, (i) {
                final isActive = _activeFilter == options[i];
                return GestureDetector(
                  onTap: () => setState(() => _activeFilter = options[i]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.orange
                          : const Color(0xFF0D1F3C),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (widget.filterYear != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.orange,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${widget.filterYear}',
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadContracts,
              child: const Text(
                'Tentar novamente',
                style: TextStyle(color: AppColors.orange),
              ),
            ),
          ],
        ),
      );
    }

    final contracts = _filtered;
    if (contracts.isEmpty) return _buildEmpty();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: contracts.length,
      itemBuilder: (context, i) => _buildCard(contracts[i]),
    );
  }

  Widget _buildCard(Contract contract) {
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ContratoDetailScreen(
              transportId: widget.transportId,
              studentId: widget.studentId,
              studentName: widget.studentName,
              driverUid: widget.driverUid,
              contract: contract,
            ),
          ),
        );
        if (changed == true) _loadContracts();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1F3C),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcone(contract.status),
            const SizedBox(height: 10),
            Text(
              contract.fileName,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatShortDate(contract.startDate)} — ${_formatShortDate(contract.endDate)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
              ),
            ),
            const Spacer(),
            StatusBadge(
              status: _toBadgeType(contract.status),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              textStyle: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcone(ContractStatus status) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _iconBgColor(status),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_iconData(status), color: _iconColor(status), size: 20),
    );
  }

  Widget _buildEmpty() {
    final isFiltered = _activeFilter != null || widget.filterYear != null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            color: Colors.white.withValues(alpha: 0.2),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'Nenhum contrato nesta categoria'
                : 'Nenhum contrato cadastrado',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 8),
            Text(
              'Toque em + para anexar o primeiro contrato',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openAttachScreen() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ContractAttachScreen(
          transportId: widget.transportId,
          studentId: widget.studentId,
          studentName: widget.studentName,
          driverUid: widget.driverUid,
        ),
      ),
    );
    if (created == true) _loadContracts();
  }

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

  StatusBadgeType _toBadgeType(ContractStatus status) {
    switch (status) {
      case ContractStatus.pending:
        return StatusBadgeType.pendente;
      case ContractStatus.approved:
        return StatusBadgeType.assinado;
      case ContractStatus.cancelled:
        return StatusBadgeType.cancelado;
    }
  }

  IconData _iconData(ContractStatus status) {
    switch (status) {
      case ContractStatus.pending:
        return Icons.article_outlined;
      case ContractStatus.approved:
        return Icons.check_circle_outline;
      case ContractStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _iconColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.pending:
        return AppColors.orange;
      case ContractStatus.approved:
        return const Color(0xFF42E21E);
      case ContractStatus.cancelled:
        return const Color(0xFFFF2B2B);
    }
  }

  Color _iconBgColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.pending:
        return AppColors.orange.withValues(alpha: 0.15);
      case ContractStatus.approved:
        return const Color(0xFF1D5E52);
      case ContractStatus.cancelled:
        return const Color(0xFF6A3242);
    }
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
  }
}

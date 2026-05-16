import 'package:intl/intl.dart';
import 'package:niccioli/app/models/app_user_profile.dart';
import 'package:niccioli/app/models/contract.dart';
import 'package:niccioli/app/services/auth_service.dart';
import 'package:niccioli/app/services/contract_service.dart';
import 'package:niccioli/app/services/transport_service.dart';

class FirebaseContextService {
  static Future<String> buildContext() async {
    try {
      final profile = await AuthService.instance.loadCurrentUserProfile();
      if (profile == null) return '';
      if (profile.role == AppUserRole.motorista) {
        return _buildDriverContext(profile);
      } else {
        return _buildStudentContext(profile);
      }
    } catch (_) {
      return '';
    }
  }

  static Future<String> _buildDriverContext(AppUserProfile profile) async {
    final transport =
        await TransportService.instance.loadCurrentDriverTransport();
    if (transport == null) return '';

    final presences =
        await TransportService.instance.loadTodayDriverPresences();

    final students = transport.studentSummaries.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final contractFutures = students.map<Future<List<Contract>>>((s) async {
      try {
        return await ContractService.instance
            .listContracts(transport.id, s.uid);
      } catch (_) {
        return [];
      }
    }).toList();
    final allContracts = await Future.wait(contractFutures);

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final sb = StringBuffer();

    sb.writeln('=== DADOS DO MOTORISTA ===');
    sb.writeln('Nome: ${profile.name}');
    sb.writeln(
      'Veículo: ${transport.vehicleModel ?? '-'} | Placa: ${transport.licensePlate ?? '-'}',
    );
    sb.writeln(
      'Prazo da lista: ${transport.defaultListDeadline ?? '17:00'}',
    );
    sb.writeln();

    sb.writeln('=== ALUNOS CADASTRADOS (${students.length}) ===');
    for (var i = 0; i < students.length; i++) {
      final student = students[i];
      final active = _activeContract(allContracts[i]);
      final contractInfo = active != null
          ? 'R\$ ${_brl(active.monthlyValue)}/mês, vence dia ${active.paymentDay}, ${active.status.displayLabel.toLowerCase()}'
          : 'sem contrato';
      sb.writeln(
        '- ${student.name} | ${student.university ?? '-'} | Ponto: ${student.defaultPickupPoint ?? '-'} | Contrato: $contractInfo',
      );
    }
    sb.writeln();

    sb.writeln('=== PRESENÇAS HOJE ($today) ===');
    final confirmed = students
        .where((s) => presences[s.uid]?.outboundStatus == 'confirmed')
        .map((s) => s.name)
        .toList();
    final notReturning = students
        .where((s) => presences[s.uid]?.returnStatus == 'notReturning')
        .map((s) => s.name)
        .toList();
    final noResponse = students.where((s) {
      final p = presences[s.uid];
      return p == null ||
          p.outboundStatus == null ||
          p.outboundStatus!.isEmpty;
    }).map((s) => s.name).toList();

    sb.writeln(
      'Confirmaram IDA: ${confirmed.isEmpty ? '(nenhum)' : confirmed.join(', ')}',
    );
    sb.writeln(
      'Não voltarão: ${notReturning.isEmpty ? '(nenhum)' : notReturning.join(', ')}',
    );
    sb.writeln(
      'Sem resposta: ${noResponse.isEmpty ? '(nenhum)' : noResponse.join(', ')}',
    );

    return sb.toString();
  }

  static Future<String> _buildStudentContext(AppUserProfile profile) async {
    final transport =
        await TransportService.instance.loadCurrentStudentTransport();
    final presence =
        await TransportService.instance.loadTodayPresenceResponse();

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final sb = StringBuffer();

    sb.writeln('=== DADOS DO ALUNO ===');
    sb.writeln('Nome: ${profile.name}');
    sb.writeln('Universidade: ${profile.university ?? '-'}');
    sb.writeln('Ponto de embarque: ${profile.defaultPickupPoint ?? '-'}');
    sb.writeln();

    if (transport != null) {
      sb.writeln('=== TRANSPORTE ===');
      sb.writeln('Motorista: ${transport.driverName}');
      sb.writeln(
        'Veículo: ${transport.vehicleModel ?? '-'} | Placa: ${transport.licensePlate ?? '-'}',
      );
      sb.writeln(
        'Prazo da lista: ${transport.defaultListDeadline ?? '-'}',
      );
      sb.writeln();

      final contracts = await ContractService.instance
          .listContracts(transport.id, profile.uid);
      if (contracts.isNotEmpty) {
        final fmt = DateFormat('dd/MM/yyyy');
        sb.writeln('=== CONTRATOS ===');
        for (final c in contracts) {
          sb.writeln(
            '- R\$ ${_brl(c.monthlyValue)}/mês, vence dia ${c.paymentDay} | Status: ${c.status.displayLabel} | Período: ${fmt.format(c.startDate)} a ${fmt.format(c.endDate)}',
          );
        }
        sb.writeln();
      }
    } else {
      sb.writeln('=== TRANSPORTE ===');
      sb.writeln('Não vinculado a nenhum transporte.');
      sb.writeln();
    }

    sb.writeln('=== PRESENÇA HOJE ($today) ===');
    sb.writeln('IDA: ${_presenceLabel(presence.outboundStatus)}');
    sb.writeln('VOLTA: ${_presenceLabel(presence.returnStatus)}');

    return sb.toString();
  }

  static Contract? _activeContract(List<Contract> contracts) {
    if (contracts.isEmpty) return null;
    final approved =
        contracts.where((c) => c.status == ContractStatus.approved).toList();
    if (approved.isNotEmpty) return approved.first;
    final pending =
        contracts.where((c) => c.status == ContractStatus.pending).toList();
    if (pending.isNotEmpty) return pending.first;
    return contracts.first;
  }

  static String _presenceLabel(String? status) {
    switch (status) {
      case 'confirmed':
        return 'confirmada';
      case 'cancelled':
        return 'cancelada';
      case 'notReturning':
        return 'não volta';
      default:
        return 'sem resposta';
    }
  }

  static String _brl(double value) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: '').format(value).trim();
}

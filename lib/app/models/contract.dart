import 'package:cloud_firestore/cloud_firestore.dart';

enum ContractStatus { pending, approved, cancelled }

extension ContractStatusX on ContractStatus {
  String get firestoreValue {
    switch (this) {
      case ContractStatus.pending:
        return 'pending';
      case ContractStatus.approved:
        return 'approved';
      case ContractStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayLabel {
    switch (this) {
      case ContractStatus.pending:
        return 'Pendente';
      case ContractStatus.approved:
        return 'Aprovado';
      case ContractStatus.cancelled:
        return 'Cancelado';
    }
  }

  static ContractStatus fromString(String? value) {
    switch (value) {
      case 'approved':
        return ContractStatus.approved;
      case 'cancelled':
        return ContractStatus.cancelled;
      default:
        return ContractStatus.pending;
    }
  }
}

class Contract {
  const Contract({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    this.signedFileUrl,
    required this.startDate,
    required this.endDate,
    required this.monthlyValue,
    required this.paymentDay,
    this.observations,
    required this.status,
    this.signedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fileName;
  final String fileUrl;
  final String? signedFileUrl;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyValue;
  final int paymentDay;
  final String? observations;
  final ContractStatus status;
  final DateTime? signedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Contract.fromMap(Map<String, dynamic> data) {
    return Contract(
      id: (data['id'] as String?) ?? '',
      fileName: (data['fileName'] as String?) ?? '',
      fileUrl: (data['fileUrl'] as String?) ?? '',
      signedFileUrl: data['signedFileUrl'] as String?,
      startDate: _toDateTime(data['startDate']),
      endDate: _toDateTime(data['endDate']),
      monthlyValue: (data['monthlyValue'] as num?)?.toDouble() ?? 0.0,
      paymentDay: (data['paymentDay'] as int?) ?? 1,
      observations: data['observations'] as String?,
      status: ContractStatusX.fromString(data['status'] as String?),
      signedAt: data['signedAt'] != null ? _toDateTime(data['signedAt']) : null,
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'signedFileUrl': signedFileUrl,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'monthlyValue': monthlyValue,
      'paymentDay': paymentDay,
      'observations': observations,
      'status': status.firestoreValue,
      'signedAt': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Contract copyWith({
    String? id,
    String? fileName,
    String? fileUrl,
    String? signedFileUrl,
    DateTime? startDate,
    DateTime? endDate,
    double? monthlyValue,
    int? paymentDay,
    String? observations,
    ContractStatus? status,
    DateTime? signedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contract(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      signedFileUrl: signedFileUrl ?? this.signedFileUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      monthlyValue: monthlyValue ?? this.monthlyValue,
      paymentDay: paymentDay ?? this.paymentDay,
      observations: observations ?? this.observations,
      status: status ?? this.status,
      signedAt: signedAt ?? this.signedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

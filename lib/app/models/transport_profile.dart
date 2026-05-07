import 'package:cloud_firestore/cloud_firestore.dart';

class TransportStudentSummary {
  const TransportStudentSummary({
    required this.uid,
    required this.name,
    this.university,
    this.defaultPickupPoint,
    this.alternatePickupPoints = const [],
  });

  final String uid;
  final String name;
  final String? university;
  final String? defaultPickupPoint;
  final List<String> alternatePickupPoints;

  factory TransportStudentSummary.fromMap(
    String uid,
    Map<String, dynamic> data,
  ) {
    return TransportStudentSummary(
      uid: uid,
      name: (data['name'] as String?) ?? '',
      university: data['university'] as String?,
      defaultPickupPoint: data['defaultPickupPoint'] as String?,
      alternatePickupPoints:
          (data['alternatePickupPoints'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'university': university,
      'defaultPickupPoint': defaultPickupPoint,
      'alternatePickupPoints': alternatePickupPoints,
    };
  }
}

class TransportProfile {
  const TransportProfile({
    required this.id,
    required this.driverUid,
    required this.driverName,
    this.vehicleModel,
    this.licensePlate,
    this.defaultListDeadline,
    this.studentUids = const [],
    this.studentSummaries = const {},
  });

  final String id;
  final String driverUid;
  final String driverName;
  final String? vehicleModel;
  final String? licensePlate;
  final String? defaultListDeadline;
  final List<String> studentUids;
  final Map<String, TransportStudentSummary> studentSummaries;

  factory TransportProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw const FormatException('Transporte sem dados.');
    }

    final rawSummaries = data['studentSummaries'];
    final summaries = <String, TransportStudentSummary>{};
    if (rawSummaries is Map<String, dynamic>) {
      for (final entry in rawSummaries.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          summaries[entry.key] = TransportStudentSummary.fromMap(
            entry.key,
            value,
          );
        }
      }
    }

    return TransportProfile(
      id: snapshot.id,
      driverUid: (data['driverUid'] as String?) ?? '',
      driverName: (data['driverName'] as String?) ?? '',
      vehicleModel: data['vehicleModel'] as String?,
      licensePlate: data['licensePlate'] as String?,
      defaultListDeadline: data['defaultListDeadline'] as String?,
      studentUids:
          (data['studentUids'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      studentSummaries: summaries,
    );
  }
}

class PresenceResponse {
  const PresenceResponse({
    this.outboundStatus,
    this.returnStatus,
    this.alternatePickupPoint,
  });

  final String? outboundStatus;
  final String? returnStatus;
  final String? alternatePickupPoint;

  factory PresenceResponse.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const PresenceResponse();
    }
    return PresenceResponse(
      outboundStatus: data['outboundStatus'] as String?,
      returnStatus: data['returnStatus'] as String?,
      alternatePickupPoint: data['alternatePickupPoint'] as String?,
    );
  }
}

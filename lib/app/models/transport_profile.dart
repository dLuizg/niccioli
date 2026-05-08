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
    this.servedInstitutions = const [],
    this.studentUids = const [],
  });

  final String id;
  final String driverUid;
  final String driverName;
  final String? vehicleModel;
  final String? licensePlate;
  final String? defaultListDeadline;
  final List<String> servedInstitutions;
  final List<String> studentUids;

  factory TransportProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw const FormatException('Transporte sem dados.');
    }

    return TransportProfile(
      id: snapshot.id,
      driverUid: (data['driverUid'] as String?) ?? '',
      driverName: (data['driverName'] as String?) ?? '',
      vehicleModel: data['vehicleModel'] as String?,
      licensePlate: data['licensePlate'] as String?,
      defaultListDeadline: data['defaultListDeadline'] as String?,
      servedInstitutions:
          (data['servedInstitutions'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      studentUids:
          (data['studentUids'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
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

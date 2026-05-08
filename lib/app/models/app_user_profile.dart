import 'package:cloud_firestore/cloud_firestore.dart';

enum AppUserRole { aluno, motorista }

extension AppUserRoleX on AppUserRole {
  String get firestoreValue {
    switch (this) {
      case AppUserRole.aluno:
        return 'aluno';
      case AppUserRole.motorista:
        return 'motorista';
    }
  }

  String get displayLabel {
    switch (this) {
      case AppUserRole.aluno:
        return 'Aluno';
      case AppUserRole.motorista:
        return 'Motorista';
    }
  }

  static AppUserRole? fromFirestoreValue(String? value) {
    switch (value) {
      case 'aluno':
        return AppUserRole.aluno;
      case 'motorista':
        return AppUserRole.motorista;
      default:
        return null;
    }
  }
}

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.document,
    required this.role,
    required this.university,
    this.phone,
    this.address,
    this.defaultPickupPoint,
    this.alternatePickupPoints = const [],
    this.vehicle,
    this.licensePlate,
    this.studentUids = const [],
    this.driverUid,
    this.defaultListDeadline,
  });

  final String uid;
  final String email;
  final String name;
  final String document;
  final AppUserRole role;
  final String? university;
  final String? phone;
  final String? address;
  final String? defaultPickupPoint;
  final List<String> alternatePickupPoints;
  final String? vehicle;
  final String? licensePlate;
  final List<String> studentUids;
  final String? driverUid;
  final String? defaultListDeadline;

  String get profileLabel => '${role.displayLabel} - Niccioli';

  factory AppUserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    final role = AppUserRoleX.fromFirestoreValue(data['role'] as String?);
    if (role == null) {
      throw const FormatException('Perfil com tipo de usuario invalido.');
    }

    return AppUserProfile(
      uid: uid,
      email: (data['email'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      document: (data['document'] as String?) ?? '',
      role: role,
      university: data['university'] as String?,
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      defaultPickupPoint: data['defaultPickupPoint'] as String?,
      alternatePickupPoints:
          (data['alternatePickupPoints'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      vehicle: data['vehicle'] as String?,
      licensePlate: data['licensePlate'] as String?,
      studentUids:
          (data['studentUids'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      driverUid: data['driverUid'] as String?,
      defaultListDeadline: data['defaultListDeadline'] as String?,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'document': document,
      'role': role.firestoreValue,
      'university': role == AppUserRole.aluno ? university : null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

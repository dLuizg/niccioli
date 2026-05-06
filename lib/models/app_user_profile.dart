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
  });

  final String uid;
  final String email;
  final String name;
  final String document;
  final AppUserRole role;
  final String? university;

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

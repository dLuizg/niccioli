import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:niccioli/app/models/contract.dart';
import 'package:niccioli/app/services/auth_service.dart';

class ContractFailure implements Exception {
  const ContractFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class ContractService {
  ContractService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  static final ContractService instance = ContractService();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _studentDoc(
    String transportId,
    String studentId,
  ) {
    return _firestore
        .collection('transport')
        .doc(transportId)
        .collection('students-list')
        .doc(studentId);
  }

  Reference _pdfRef(
    String driverUid,
    String studentId,
    String contractId,
    String fileName,
  ) {
    return _storage.ref(
      'contracts/$driverUid/$studentId/$contractId/$fileName',
    );
  }

  Future<List<Contract>> listContracts(
    String transportId,
    String studentId,
  ) async {
    try {
      final snapshot = await _studentDoc(transportId, studentId).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return const [];
      final raw = data['contracts'];
      if (raw is! List) return const [];
      final contracts = raw
          .whereType<Map<String, dynamic>>()
          .map(Contract.fromMap)
          .toList();
      contracts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return contracts;
    } on FirebaseException catch (error) {
      throw ContractFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<void> createContract(
    String transportId,
    String studentId,
    Contract contract,
  ) async {
    try {
      await _studentDoc(transportId, studentId).set(
        {'contracts': FieldValue.arrayUnion([contract.toMap()])},
        SetOptions(merge: true),
      );
    } on FirebaseException catch (error) {
      throw ContractFailure(AuthService.firebaseMessageFor(error));
    }
  }

  // Read-modify-write: necessary because arrayRemove requires exact Timestamp
  // equality, which is unreliable after serialization round-trips.
  Future<void> updateContract(
    String transportId,
    String studentId,
    Contract contract,
  ) async {
    try {
      final snapshot = await _studentDoc(transportId, studentId).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw const ContractFailure('Contrato não encontrado.');
      }
      final raw = data['contracts'];
      final current = raw is List
          ? raw.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      final updated = current.map((m) {
        return (m['id'] as String?) == contract.id ? contract.toMap() : m;
      }).toList();
      await _studentDoc(transportId, studentId).update({'contracts': updated});
    } on ContractFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw ContractFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<void> cancelContract(
    String transportId,
    String studentId,
    String contractId,
  ) async {
    try {
      final snapshot = await _studentDoc(transportId, studentId).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return;
      final raw = data['contracts'];
      final current = raw is List
          ? raw.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      final updated = current.map((m) {
        if ((m['id'] as String?) == contractId) {
          return {
            ...m,
            'status': ContractStatus.cancelled.firestoreValue,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          };
        }
        return m;
      }).toList();
      await _studentDoc(transportId, studentId).update({'contracts': updated});
    } on FirebaseException catch (error) {
      throw ContractFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<String> uploadOriginalPdf({
    required String driverUid,
    required String studentId,
    required String contractId,
    required Uint8List bytes,
  }) async {
    try {
      final ref = _pdfRef(driverUid, studentId, contractId, 'original.pdf');
      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'application/pdf'),
      );
      return await task.ref.getDownloadURL();
    } on FirebaseException catch (error) {
      throw ContractFailure(
        'Falha ao enviar PDF: ${AuthService.firebaseMessageFor(error)}',
      );
    }
  }

  Future<void> uploadSignedPdf({
    required String transportId,
    required String driverUid,
    required String studentId,
    required String contractId,
    required Uint8List bytes,
    required Contract original,
  }) async {
    try {
      final ref = _pdfRef(driverUid, studentId, contractId, 'signed.pdf');
      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'application/pdf'),
      );
      final signedUrl = await task.ref.getDownloadURL();
      final now = DateTime.now();
      final updated = original.copyWith(
        signedFileUrl: signedUrl,
        status: ContractStatus.approved,
        signedAt: now,
        updatedAt: now,
      );
      await updateContract(transportId, studentId, updated);
    } on ContractFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw ContractFailure(
        'Falha ao enviar PDF assinado: ${AuthService.firebaseMessageFor(error)}',
      );
    }
  }

  String generateId() => _firestore.collection('_').doc().id;
}

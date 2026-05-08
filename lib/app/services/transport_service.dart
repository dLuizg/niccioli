import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:niccioli/app/models/app_user_profile.dart';
import 'package:niccioli/app/models/transport_profile.dart';
import 'package:niccioli/app/services/auth_service.dart';
import 'package:niccioli/app/utils/br_value_masks.dart';

class TransportService {
  TransportService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static final TransportService instance = TransportService();

  static const presenceListCollection = 'presence-list';
  static const studentsListCollection = 'students-list';

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  User? get _currentUser => _firebaseAuth.currentUser;

  Future<TransportProfile?> loadCurrentDriverTransport() async {
    final driver = await _loadCurrentDriverProfile();
    if (driver == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }

    return _loadOrMigrateDriverTransport(driver);
  }

  Future<TransportProfile?> loadCurrentStudentTransport() async {
    final user = _currentUser;
    if (user == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }

    try {
      final snapshot = await _transport
          .where('studentUids', arrayContains: user.uid)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return TransportProfile.fromFirestore(snapshot.docs.first);
    } on FormatException {
      throw const AuthFailure('Transporte invalido.');
    } on FirebaseException catch (error) {
      throw AuthFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<void> updateCurrentDriverVehicle({
    required String vehicleModel,
    required String licensePlate,
  }) async {
    final driver = await _loadCurrentDriverProfile();
    if (driver == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }

    final transportRef = await _loadOrCreateDriverTransportRef(driver);
    try {
      await transportRef.set({
        'driverUid': driver.uid,
        'driverName': driver.name,
        'vehicleModel': vehicleModel.trim(),
        'licensePlate': BrValueMasks.normalizeLicensePlate(licensePlate),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw AuthFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<void> updateCurrentDriverDefaultListDeadline(String deadline) async {
    final driver = await _loadCurrentDriverProfile();
    if (driver == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }

    final transportRef = await _loadOrCreateDriverTransportRef(driver);
    try {
      await transportRef.set({
        'driverUid': driver.uid,
        'driverName': driver.name,
        'defaultListDeadline': deadline.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw AuthFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<void> updateCurrentDriverServedInstitutions(
    List<String> institutions,
  ) async {
    final driver = await _loadCurrentDriverProfile();
    if (driver == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }

    final transportRef = await _loadOrCreateDriverTransportRef(driver);
    try {
      await transportRef.set({
        'driverUid': driver.uid,
        'driverName': driver.name,
        'servedInstitutions': _cleanStringList(institutions),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw AuthFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<void> updateCurrentDriverName(String driverName) async {
    final driver = await _loadCurrentDriverProfile();
    if (driver == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }

    final transport = await _loadDriverTransport(driver.uid);
    if (transport == null) {
      return;
    }

    try {
      await _transport.doc(transport.id).update({
        'driverName': driverName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw AuthFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<List<TransportStudentSummary>> loadCurrentDriverStudents() async {
    final driver = await _loadCurrentDriverProfile();
    if (driver == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }

    final transport = await _loadDriverTransport(driver.uid);
    if (transport == null || transport.studentUids.isEmpty) {
      return const [];
    }

    try {
      final snapshot = await _studentsListRef(transport.id).get();
      final students = <TransportStudentSummary>[];
      for (final doc in snapshot.docs) {
        try {
          students.add(TransportStudentSummary.fromMap(doc.id, doc.data()));
        } on FormatException {
          continue;
        }
      }
      students.sort((a, b) => a.name.compareTo(b.name));
      return students;
    } on FirebaseException catch (error) {
      throw AuthFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<void> addStudentToCurrentDriverByDocument(String document) async {
    final driver = await _loadCurrentDriverProfile();
    if (driver == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }

    final trimmedDocument = BrValueMasks.onlyDigits(document);
    if (trimmedDocument.isEmpty) {
      throw const AuthFailure('Informe o CPF do aluno.');
    }

    try {
      final studentDoc = await _findStudentByDocument(trimmedDocument);
      if (studentDoc == null) {
        throw const AuthFailure('Nenhum aluno encontrado com esse CPF.');
      }

      final studentProfile = AppUserProfile.fromFirestore(
        studentDoc.id,
        studentDoc.data(),
      );

      await _upsertStudentForDriver(
        driver: driver,
        studentProfile: studentProfile,
      );
    } on AuthFailure {
      rethrow;
    } on FormatException {
      throw const AuthFailure('Perfil do aluno invalido.');
    } on FirebaseException catch (error) {
      throw AuthFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<void> removeStudentFromCurrentDriver(String studentUid) async {
    final driver = await _loadCurrentDriverProfile();
    if (driver == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }

    final trimmedStudentUid = studentUid.trim();
    if (trimmedStudentUid.isEmpty) {
      throw const AuthFailure('Aluno invalido.');
    }

    final transport = await _loadDriverTransport(driver.uid);
    if (transport == null) {
      return;
    }

    try {
      final transportRef = _transport.doc(transport.id);
      final batch = _firestore.batch();
      batch.update(transportRef, {
        'studentUids': FieldValue.arrayRemove([trimmedStudentUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.delete(
        transportRef.collection(studentsListCollection).doc(trimmedStudentUid),
      );
      await batch.commit();
    } on FirebaseException catch (error) {
      throw AuthFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<PresenceResponse> loadTodayPresenceResponse() async {
    final transport = await loadCurrentStudentTransport();
    final user = _currentUser;
    if (transport == null || user == null) {
      return const PresenceResponse();
    }

    try {
      final snapshot = await _todayPresenceRef(transport).get();
      final data = snapshot.data();
      final responses = data?['responses'];
      if (responses is! Map<String, dynamic>) {
        return const PresenceResponse();
      }
      final response = responses[user.uid];
      if (response is! Map<String, dynamic>) {
        return const PresenceResponse();
      }
      return PresenceResponse.fromMap(response);
    } on FirebaseException catch (error) {
      throw AuthFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<void> updateTodayPresenceResponse({
    String? outboundStatus,
    String? returnStatus,
    String? alternatePickupPoint,
  }) async {
    final transport = await loadCurrentStudentTransport();
    final user = _currentUser;
    if (transport == null || user == null) {
      throw const AuthFailure('Voce ainda nao esta vinculado a um transporte.');
    }

    final response = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (outboundStatus != null) {
      response['outboundStatus'] = outboundStatus;
      response['outboundUpdatedAt'] = FieldValue.serverTimestamp();
    }
    if (returnStatus != null) {
      response['returnStatus'] = returnStatus;
      response['returnUpdatedAt'] = FieldValue.serverTimestamp();
    }
    if (alternatePickupPoint != null) {
      response['alternatePickupPoint'] = alternatePickupPoint.trim();
    }

    try {
      final presenceRef = _todayPresenceRef(transport);
      final snapshot = await presenceRef.get();
      final updates = <String, dynamic>{
        'date': _todayId(),
        'transportId': transport.id,
        'driverUid': transport.driverUid,
        'responses': {user.uid: response},
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!snapshot.exists) {
        updates['createdAt'] = FieldValue.serverTimestamp();
      }
      await presenceRef.set(updates, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw AuthFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<AppUserProfile?> _loadCurrentDriverProfile() async {
    final user = _currentUser;
    if (user == null) {
      return null;
    }

    final profile = await _loadUserProfile(user.uid);
    if (profile == null) {
      return null;
    }
    if (profile.role != AppUserRole.motorista) {
      throw const AuthFailure('Apenas motoristas podem gerenciar transporte.');
    }
    return profile;
  }

  Future<AppUserProfile?> _loadUserProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return AppUserProfile.fromFirestore(uid, data);
  }

  Future<TransportProfile?> _loadDriverTransport(String driverUid) async {
    try {
      final snapshot = await _loadDriverTransportSnapshot(driverUid);
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return TransportProfile.fromFirestore(snapshot.docs.first);
    } on FormatException {
      throw const AuthFailure('Transporte invalido.');
    } on FirebaseException catch (error) {
      throw AuthFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<TransportProfile?> _loadOrMigrateDriverTransport(
    AppUserProfile driver,
  ) async {
    try {
      final snapshot = await _loadDriverTransportSnapshot(driver.uid);
      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      if (data.containsKey('servedInstitutions')) {
        return TransportProfile.fromFirestore(doc);
      }

      final legacyInstitutions = await _loadLegacyServedInstitutions(
        driver.uid,
      );
      await doc.reference.set({
        'servedInstitutions': legacyInstitutions,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final migratedDoc = await doc.reference.get();
      return TransportProfile.fromFirestore(migratedDoc);
    } on FormatException {
      throw const AuthFailure('Transporte invalido.');
    } on FirebaseException catch (error) {
      throw AuthFailure(AuthService.firebaseMessageFor(error));
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _loadDriverTransportSnapshot(
    String driverUid,
  ) {
    return _transport.where('driverUid', isEqualTo: driverUid).limit(1).get();
  }

  Future<DocumentReference<Map<String, dynamic>>>
  _loadOrCreateDriverTransportRef(AppUserProfile driver) async {
    final snapshot = await _transport
        .where('driverUid', isEqualTo: driver.uid)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.reference;
    }

    final ref = _transport.doc();
    final legacyInstitutions = await _loadLegacyServedInstitutions(driver.uid);
    await ref.set({
      'driverUid': driver.uid,
      'driverName': driver.name,
      'servedInstitutions': legacyInstitutions,
      'studentUids': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref;
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findStudentByDocument(
    String document,
  ) async {
    final snapshot = await _users
        .where('document', isEqualTo: document)
        .limit(5)
        .get();

    for (final doc in snapshot.docs) {
      if (doc.data()['role'] == AppUserRole.aluno.firestoreValue) {
        return doc;
      }
    }
    return null;
  }

  Future<List<String>> _loadLegacyServedInstitutions(String driverUid) async {
    final snapshot = await _users.doc(driverUid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return const [];
    }
    return _cleanStringList(data['servedInstitutions'] as List<dynamic>?);
  }

  List<String> _cleanStringList(Iterable<dynamic>? values) {
    return values
            ?.whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList() ??
        const [];
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  _loadTransportAssignedToStudent(String studentUid) async {
    final transportSnapshot = await _transport
        .where('studentUids', arrayContains: studentUid)
        .limit(1)
        .get();
    if (transportSnapshot.docs.isEmpty) {
      return null;
    }

    return transportSnapshot.docs.first;
  }

  Future<void> _upsertStudentForDriver({
    required AppUserProfile driver,
    required AppUserProfile studentProfile,
  }) async {
    final assignedTransportDoc = await _loadTransportAssignedToStudent(
      studentProfile.uid,
    );
    final transportRef = assignedTransportDoc?.reference;
    if (assignedTransportDoc != null) {
      final assignedTransport = TransportProfile.fromFirestore(
        assignedTransportDoc,
      );
      if (assignedTransport.driverUid != driver.uid) {
        throw const AuthFailure(
          'Este aluno ja esta vinculado a outro motorista.',
        );
      }
    }

    final currentDriverTransportRef =
        transportRef ?? await _loadOrCreateDriverTransportRef(driver);
    final studentSummaryRef = currentDriverTransportRef
        .collection(studentsListCollection)
        .doc(studentProfile.uid);
    final batch = _firestore.batch();
    batch.set(currentDriverTransportRef, {
      'driverUid': driver.uid,
      'driverName': driver.name,
      'studentUids': FieldValue.arrayUnion([studentProfile.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(studentSummaryRef, {
      ..._summaryFromProfile(studentProfile).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();

    final verifiedSummary = await studentSummaryRef.get(
      const GetOptions(source: Source.server),
    );
    if (!verifiedSummary.exists) {
      throw const AuthFailure(
        'Nao foi possivel criar o aluno na lista do transporte.',
      );
    }
  }

  TransportStudentSummary _summaryFromProfile(AppUserProfile profile) {
    return TransportStudentSummary(
      uid: profile.uid,
      name: profile.name,
      university: profile.university,
      defaultPickupPoint: profile.defaultPickupPoint,
      alternatePickupPoints: profile.alternatePickupPoints,
    );
  }

  DocumentReference<Map<String, dynamic>> _todayPresenceRef(
    TransportProfile transport,
  ) {
    return _transport
        .doc(transport.id)
        .collection(presenceListCollection)
        .doc(_todayId());
  }

  CollectionReference<Map<String, dynamic>> _studentsListRef(
    String transportId,
  ) {
    return _transport.doc(transportId).collection(studentsListCollection);
  }

  String _todayId() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  CollectionReference<Map<String, dynamic>> get _transport =>
      _firestore.collection('transport');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
}

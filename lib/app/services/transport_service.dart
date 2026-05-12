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

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  User? get _currentUser => _firebaseAuth.currentUser;

  Future<TransportProfile?> loadCurrentDriverTransport() async {
    final driver = await _loadCurrentDriverProfile();
    if (driver == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }

    return _loadDriverTransport(driver.uid);
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

  Future<List<AppUserProfile>> loadCurrentDriverStudents() async {
    final driver = await _loadCurrentDriverProfile();
    if (driver == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }

    final transport = await _loadDriverTransport(driver.uid);
    if (transport == null || transport.studentUids.isEmpty) {
      return const [];
    }

    try {
      final students = <AppUserProfile>[];
      for (final uid in transport.studentUids) {
        final student = await _loadUserProfile(uid);
        if (student != null && student.role == AppUserRole.aluno) {
          students.add(student);
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

      await _ensureStudentIsAvailable(studentProfile, driver.uid);

      final transportRef = await _loadOrCreateDriverTransportRef(driver);
      await transportRef.set({
        'driverUid': driver.uid,
        'driverName': driver.name,
        'studentUids': FieldValue.arrayUnion([studentProfile.uid]),
        'studentSummaries': {
          studentProfile.uid: _summaryFromProfile(studentProfile).toMap(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
      await _transport.doc(transport.id).update({
        'studentUids': FieldValue.arrayRemove([trimmedStudentUid]),
        FieldPath(['studentSummaries', trimmedStudentUid]): FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
      final snapshot = await _transport
          .where('driverUid', isEqualTo: driverUid)
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
    await ref.set({
      'driverUid': driver.uid,
      'driverName': driver.name,
      'studentUids': <String>[],
      'studentSummaries': <String, dynamic>{},
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

  Future<void> _ensureStudentIsAvailable(
    AppUserProfile student,
    String driverUid,
  ) async {
    final transportSnapshot = await _transport
        .where('studentUids', arrayContains: student.uid)
        .limit(1)
        .get();
    if (transportSnapshot.docs.isEmpty) {
      return;
    }

    final assignedTransport = TransportProfile.fromFirestore(
      transportSnapshot.docs.first,
    );
    if (assignedTransport.driverUid == driverUid) {
      throw const AuthFailure('Este aluno ja esta na sua lista.');
    }
    throw const AuthFailure('Este aluno ja esta vinculado a outro motorista.');
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

  String _todayId() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  CollectionReference<Map<String, dynamic>> get _transport =>
      _firestore.collection('transport');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:niccioli/models/app_user_profile.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static final AuthService instance = AuthService();

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<AppUserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final profile = await loadUserProfile(credential.user!.uid);
      if (profile == null) {
        await signOut();
        throw const AuthFailure(
          'Perfil nao encontrado. Entre em contato com o suporte.',
        );
      }
      return profile;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(authMessageFor(error));
    } on FirebaseException catch (error) {
      throw AuthFailure(firebaseMessageFor(error));
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        'Nao foi possivel entrar. Tente novamente em instantes.',
      );
    }
  }

  Future<AppUserProfile?> loadCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }
    return loadUserProfile(user.uid);
  }

  Future<AppUserProfile?> loadUserProfile(String uid) async {
    try {
      final snapshot = await _users.doc(uid).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return AppUserProfile.fromFirestore(uid, data);
    } on FormatException {
      return null;
    } on FirebaseException catch (error) {
      throw AuthFailure(firebaseMessageFor(error));
    }
  }

  Future<AppUserProfile?> updateCurrentUserProfile({
    String? name,
    String? phone,
    String? address,
    String? defaultPickupPoint,
    String? university,
    List<String>? alternatePickupPoints,
    String? vehicle,
    String? licensePlate,
    List<String>? servedInstitutions,
    String? defaultListDeadline,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }

    final trimmedUniversity = university?.trim();
    if (trimmedUniversity != null) {
      final currentProfile = await loadUserProfile(user.uid);
      final existingUniversity = currentProfile?.university?.trim() ?? '';
      if (existingUniversity.isNotEmpty &&
          trimmedUniversity != existingUniversity) {
        throw const AuthFailure(
          'A instituicao nao pode ser alterada depois de definida.',
        );
      }
    }

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) {
      updates['name'] = name.trim();
    }
    if (phone != null) {
      updates['phone'] = phone.trim();
    }
    if (address != null) {
      updates['address'] = address.trim();
    }
    if (defaultPickupPoint != null) {
      updates['defaultPickupPoint'] = defaultPickupPoint.trim();
    }
    if (trimmedUniversity != null) {
      updates['university'] = trimmedUniversity;
    }
    if (alternatePickupPoints != null) {
      updates['alternatePickupPoints'] = alternatePickupPoints
          .map((point) => point.trim())
          .where((point) => point.isNotEmpty)
          .toList();
    }
    if (vehicle != null) {
      updates['vehicle'] = vehicle.trim();
    }
    if (licensePlate != null) {
      updates['licensePlate'] = licensePlate.trim();
    }
    if (servedInstitutions != null) {
      updates['servedInstitutions'] = servedInstitutions
          .map((institution) => institution.trim())
          .where((institution) => institution.isNotEmpty)
          .toList();
    }
    if (defaultListDeadline != null) {
      updates['defaultListDeadline'] = defaultListDeadline.trim();
    }

    try {
      await _users.doc(user.uid).update(updates);
      return loadUserProfile(user.uid);
    } on FirebaseException catch (error) {
      throw AuthFailure(firebaseMessageFor(error));
    }
  }

  Future<List<AppUserProfile>> loadCurrentDriverStudents() async {
    final driver = await loadCurrentUserProfile();
    if (driver == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }
    if (driver.role != AppUserRole.motorista) {
      throw const AuthFailure('Apenas motoristas podem gerenciar alunos.');
    }
    if (driver.studentUids.isEmpty) {
      return const [];
    }

    try {
      final students = <AppUserProfile>[];
      for (final uid in driver.studentUids) {
        final student = await loadUserProfile(uid);
        if (student != null && student.role == AppUserRole.aluno) {
          students.add(student);
        }
      }
      students.sort((a, b) => a.name.compareTo(b.name));
      return students;
    } on FirebaseException catch (error) {
      throw AuthFailure(firebaseMessageFor(error));
    }
  }

  Future<void> addStudentToCurrentDriverByDocument(String document) async {
    final driver = await loadCurrentUserProfile();
    if (driver == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }
    if (driver.role != AppUserRole.motorista) {
      throw const AuthFailure('Apenas motoristas podem gerenciar alunos.');
    }

    final trimmedDocument = document.trim();
    if (trimmedDocument.isEmpty) {
      throw const AuthFailure('Informe o CPF do aluno.');
    }

    try {
      final snapshot = await _users
          .where('document', isEqualTo: trimmedDocument)
          .limit(5)
          .get();
      final studentDoc = snapshot.docs
          .where(
            (doc) => doc.data()['role'] == AppUserRole.aluno.firestoreValue,
          )
          .firstOrNull;

      if (studentDoc == null) {
        throw const AuthFailure('Nenhum aluno encontrado com esse CPF.');
      }

      if (driver.studentUids.contains(studentDoc.id)) {
        throw const AuthFailure('Este aluno ja esta na sua lista.');
      }

      final studentProfile = AppUserProfile.fromFirestore(
        studentDoc.id,
        studentDoc.data(),
      );
      final existingDriverUid = studentProfile.driverUid?.trim() ?? '';
      if (existingDriverUid.isNotEmpty && existingDriverUid != driver.uid) {
        throw const AuthFailure(
          'Este aluno ja esta vinculado a outro motorista.',
        );
      }

      final batch = _firestore.batch();
      batch.update(_users.doc(driver.uid), {
        'studentUids': FieldValue.arrayUnion([studentDoc.id]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(studentDoc.reference, {
        'driverUid': driver.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on AuthFailure {
      rethrow;
    } on FormatException {
      throw const AuthFailure('Perfil do aluno invalido.');
    } on FirebaseException catch (error) {
      throw AuthFailure(firebaseMessageFor(error));
    }
  }

  Future<void> removeStudentFromCurrentDriver(String studentUid) async {
    final driver = await loadCurrentUserProfile();
    if (driver == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }
    if (driver.role != AppUserRole.motorista) {
      throw const AuthFailure('Apenas motoristas podem gerenciar alunos.');
    }

    final trimmedStudentUid = studentUid.trim();
    if (trimmedStudentUid.isEmpty) {
      throw const AuthFailure('Aluno invalido.');
    }

    try {
      final studentRef = _users.doc(trimmedStudentUid);
      final studentSnapshot = await studentRef.get();
      final studentData = studentSnapshot.data();

      final batch = _firestore.batch();
      batch.update(_users.doc(driver.uid), {
        'studentUids': FieldValue.arrayRemove([trimmedStudentUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (studentSnapshot.exists &&
          studentData != null &&
          studentData['driverUid'] == driver.uid) {
        batch.update(studentRef, {
          'driverUid': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } on FirebaseException catch (error) {
      throw AuthFailure(firebaseMessageFor(error));
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  static String authMessageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Digite um e-mail valido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Ja existe uma conta com este e-mail.';
      case 'operation-not-allowed':
        return 'Login por e-mail e senha nao esta habilitado no Firebase.';
      case 'too-many-requests':
        return 'Muitas tentativas em pouco tempo. Aguarde alguns minutos e tente novamente.';
      case 'app-not-authorized':
        return 'Este app Android nao esta autorizado no Firebase. Confira o pacote com.niccioli.app.';
      case 'internal-error':
        return 'Erro interno do Firebase Auth. Tente novamente em instantes.';
      case 'weak-password':
        return 'Use uma senha com pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sem conexao com a internet. Verifique sua rede.';
      default:
        return 'Nao foi possivel autenticar. Tente novamente.';
    }
  }

  static String firebaseMessageFor(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Sem permissao para acessar seu perfil.';
      case 'unavailable':
        return 'Firebase indisponivel no momento. Tente novamente.';
      default:
        return 'Nao foi possivel acessar seu perfil. Tente novamente.';
    }
  }
}

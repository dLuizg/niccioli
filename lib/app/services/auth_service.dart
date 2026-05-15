import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:niccioli/app/models/app_user_profile.dart';
import 'package:niccioli/app/utils/br_value_masks.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseStorage? firebaseStorage,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  static final AuthService instance = AuthService();
  static const int maxProfilePhotoBytes = 5 * 1024 * 1024;
  static const Set<String> _profilePhotoExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _firebaseStorage;

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
      updates['phone'] = BrValueMasks.onlyDigits(phone);
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

  Future<AppUserProfile?> updateCurrentUserProfilePhoto({
    required String filePath,
    required String fileName,
    required int fileSize,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthFailure('Usuario nao autenticado.');
    }

    final extension = _profilePhotoExtension(fileName);
    if (extension == null) {
      throw const AuthFailure('Use uma imagem JPG, PNG ou WEBP.');
    }

    if (fileSize > maxProfilePhotoBytes) {
      throw const AuthFailure('A foto deve ter no maximo 5 MB.');
    }

    final photoFile = File(filePath);
    if (!photoFile.existsSync()) {
      throw const AuthFailure('Nao foi possivel acessar a imagem selecionada.');
    }

    final currentProfile = await loadUserProfile(user.uid);
    final previousPhotoPath = currentProfile?.photoPath?.trim();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final photoPath =
        'profilePictures/${user.uid}/avatar-$timestamp.$extension';
    final photoRef = _firebaseStorage.ref(photoPath);
    String? uploadedPhotoPath;

    try {
      final uploadTask = await photoRef.putFile(
        photoFile,
        SettableMetadata(
          contentType: _profilePhotoContentType(extension),
          customMetadata: {'uid': user.uid, 'originalName': fileName},
        ),
      );
      uploadedPhotoPath = photoPath;
      final photoUrl = await uploadTask.ref.getDownloadURL();

      await _users.doc(user.uid).update({
        'photoUrl': photoUrl,
        'photoPath': photoPath,
        'photoUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      uploadedPhotoPath = null;

      if (previousPhotoPath != null &&
          previousPhotoPath.isNotEmpty &&
          previousPhotoPath != photoPath) {
        try {
          await _firebaseStorage.ref(previousPhotoPath).delete();
        } on FirebaseException {
          // The current profile already points to the new image, so stale
          // storage cleanup should not block the user's save.
        }
      }

      return loadUserProfile(user.uid);
    } on FirebaseException catch (error) {
      if (uploadedPhotoPath != null) {
        try {
          await _firebaseStorage.ref(uploadedPhotoPath).delete();
        } on FirebaseException {
          // If the profile update failed, cleanup is best-effort only.
        }
      }
      throw AuthFailure(firebaseMessageFor(error));
    } on FileSystemException {
      throw const AuthFailure('Nao foi possivel acessar a imagem selecionada.');
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  static String? _profilePhotoExtension(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index == -1 || index == fileName.length - 1) {
      return null;
    }

    final extension = fileName.substring(index + 1).toLowerCase();
    if (!_profilePhotoExtensions.contains(extension)) {
      return null;
    }
    return extension == 'jpeg' ? 'jpg' : extension;
  }

  static String _profilePhotoContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

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
      case 'unauthorized':
        return 'Sem permissao para atualizar sua foto.';
      case 'canceled':
        return 'Envio da foto cancelado.';
      case 'quota-exceeded':
        return 'Limite de armazenamento atingido. Tente novamente mais tarde.';
      case 'unavailable':
        return 'Firebase indisponivel no momento. Tente novamente.';
      default:
        return 'Nao foi possivel acessar seu perfil. Tente novamente.';
    }
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:niccioli/app/models/app_user_profile.dart';
import 'package:niccioli/app/services/auth_service.dart';
import 'package:niccioli/app/utils/br_value_masks.dart';

class CadastroViewModel {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final documentController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  AppUserRole? selectedRole;
  String? selectedUniversity;

  bool get isAluno => selectedRole == AppUserRole.aluno;

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    documentController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<AppUserProfile> createAccount() async {
    final role = selectedRole;
    if (role == null) {
      throw const AuthFailure('Selecione seu perfil.');
    }

    if (role == AppUserRole.aluno && selectedUniversity == null) {
      throw const AuthFailure('Selecione sua universidade.');
    }

    User? createdUser;

    try {
      final viewmodel = this;
      final email = viewmodel.emailController.text.trim();
      final firebaseOptions = Firebase.app().options;

      debugPrint(
        '[Cadastro] Starting FirebaseAuth signup '
        'email=$email package=com.niccioli.app '
        'project=${firebaseOptions.projectId} appId=${firebaseOptions.appId}',
      );

      final result = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: viewmodel.emailController.text.trim(),
            password: viewmodel.passwordController.text.trim(),
          )
          .timeout(const Duration(seconds: 20));

      createdUser = result.user;
      if (createdUser == null) {
        throw const AuthFailure('Nao foi possivel criar sua conta.');
      }

      debugPrint(
        '[Cadastro] FirebaseAuth signup success uid=${createdUser.uid}',
      );

      await createdUser.updateDisplayName(nameController.text.trim());

      final profile = AppUserProfile(
        uid: createdUser.uid,
        email: emailController.text.trim(),
        name: nameController.text.trim(),
        document: BrValueMasks.onlyDigits(documentController.text),
        role: role,
        university: role == AppUserRole.aluno
            ? selectedUniversity?.trim()
            : null,
      );

      debugPrint('[Cadastro] Writing Firestore profile uid=${createdUser.uid}');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(createdUser.uid)
          .set(profile.toCreateMap());

      debugPrint('[Cadastro] Firestore profile written uid=${createdUser.uid}');

      return profile;
    } on TimeoutException catch (error) {
      debugPrint('[Cadastro] Signup timed out: $error');
      throw const AuthFailure(
        'Tempo esgotado ao criar conta. Verifique sua conexao e se Email/Senha esta habilitado no Firebase.',
      );
    } on FirebaseAuthException catch (error) {
      debugPrint(
        '[Cadastro] FirebaseAuthException code=${error.code} '
        'message=${error.message}',
      );
      if (createdUser != null) {
        await _deleteCreatedUser(createdUser);
      }
      throw AuthFailure(AuthService.authMessageFor(error));
    } on FirebaseException catch (error) {
      debugPrint(
        '[Cadastro] FirebaseException plugin=${error.plugin} '
        'code=${error.code} message=${error.message}',
      );
      if (createdUser != null) {
        await _deleteCreatedUser(createdUser);
      }
      throw AuthFailure(AuthService.firebaseMessageFor(error));
    } on AuthFailure {
      rethrow;
    } catch (_) {
      debugPrint('[Cadastro] Unknown signup failure');
      if (createdUser != null) {
        await _deleteCreatedUser(createdUser);
      }
      throw const AuthFailure(
        'Nao foi possivel criar sua conta. Tente novamente em instantes.',
      );
    }
  }

  Future<void> _deleteCreatedUser(User user) async {
    try {
      debugPrint('[Cadastro] Cleaning up partial Auth user uid=${user.uid}');
      await user.delete();
    } catch (_) {
      debugPrint('[Cadastro] Could not delete partial user; signing out.');
      await FirebaseAuth.instance.signOut();
    }
  }
}

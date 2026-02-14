import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

/// Servicio de autenticación con Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  /// Stream de cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registrar usuario con email y contraseña
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Crear documento de usuario en Firestore
        final userModel = UserModel(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          role: AppConstants.rolePassenger, // Por defecto pasajero
          rating: 0.0,
          verified: false,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .set(userModel.toFirestore());

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppConstants.errorGeneric;
    }
  }

  /// Iniciar sesión con email y contraseña
  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        return await getUserData(userCredential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppConstants.errorGeneric;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Enviar email de recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppConstants.errorGeneric;
    }
  }

  /// Obtener datos del usuario desde Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Actualizar rol del usuario
  Future<void> updateUserRole(String uid, String role) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'role': role});
  }

  /// Actualizar rating del usuario
  Future<void> updateUserRating(String uid, double newRating) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'rating': newRating});
  }

  /// Manejar excepciones de Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return AppConstants.errorWeakPassword;
      case 'email-already-in-use':
        return AppConstants.errorEmailInUse;
      case 'user-not-found':
        return AppConstants.errorUserNotFound;
      case 'wrong-password':
        return AppConstants.errorWrongPassword;
      case 'invalid-email':
        return AppConstants.errorInvalidEmail;
      default:
        return AppConstants.errorGeneric;
    }
  }
}

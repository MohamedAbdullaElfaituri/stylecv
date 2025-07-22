import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import 'auth_response.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn(
    clientId:
    '297188159916-0vt1j1pa4ph39inot3mcdr6pvtadv0ue.apps.googleusercontent.com',
  )
      : GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _userFromFirebase(User? user) {
    if (user == null) return null;

    String name = '';
    String surname = '';
    if (user.displayName != null) {
      var names = user.displayName!.split(' ');
      name = names.first;
      surname = names.length > 1 ? names.sublist(1).join(' ') : '';
    }

    return UserModel(
      id: user.uid,
      name: name,
      surname: surname,
      email: user.email ?? '',
      photoUrl: user.photoURL,
      lastLogin: DateTime.now(),
    );
  }

  Stream<UserModel?> get user {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      } else {
        final userModel = _userFromFirebase(user);
        if (userModel != null) {
          await _createUserDocument(userModel.copyWith(
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          ));
        }
        return userModel;
      }
    });
  }

  Future<AuthResponse> signUpWithEmail({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user!.updateDisplayName('$name $surname');
      await credential.user!.reload();

      final userModel = UserModel(
        id: credential.user!.uid,
        name: name,
        surname: surname,
        email: email,
        photoUrl: credential.user!.photoURL,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _createUserDocument(userModel);

      return AuthResponse(user: userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: getErrorMessage(e));
    } catch (_) {
      return AuthResponse(error: 'An unexpected error occurred. Please try again.');
    }
  }

  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userRef = _firestore.collection('users').doc(credential.user!.uid);
      final doc = await userRef.get();

      final now = DateTime.now();

      if (doc.exists) {
        await userRef.update({'lastLogin': now.toIso8601String()});
        return AuthResponse(user: UserModel.fromMap(doc.data()!));
      } else {
        final userModel = _userFromFirebase(credential.user!);
        if (userModel != null) {
          await _createUserDocument(userModel.copyWith(
            createdAt: now,
            lastLogin: now,
          ));
        }
        return AuthResponse(user: userModel);
      }
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: getErrorMessage(e));
    } catch (_) {
      return AuthResponse(error: 'An unexpected error occurred. Please try again.');
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResponse(error: 'Google sign in cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      final names = googleUser.displayName?.split(' ') ?? ['', ''];
      final userModel = UserModel(
        id: userCredential.user!.uid,
        name: names.first,
        surname: names.length > 1 ? names.sublist(1).join(' ') : '',
        email: googleUser.email,
        photoUrl: googleUser.photoUrl ?? userCredential.user!.photoURL,
        lastLogin: DateTime.now(),
      );

      await _createUserDocument(userModel);

      return AuthResponse(user: userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: getErrorMessage(e));
    } catch (_) {
      return AuthResponse(error: 'Google sign in failed. Please try again.');
    }
  }

  Future<AuthResponse> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResponse(); // Başarılı durum
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: _getErrorMessage(e));
    } catch (_) {
      return AuthResponse(error: 'Failed to send reset email. Please try again.');
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Error during sign out: $e');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    await user.reload();
    final refreshedUser = _auth.currentUser;

    final doc = await _firestore.collection('users').doc(refreshedUser?.uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return _userFromFirebase(refreshedUser);
  }

  Future<void> _createUserDocument(UserModel user) async {
    final userRef = _firestore.collection('users').doc(user.id);
    final existing = await userRef.get();

    final data = user.toMap();
    if (!existing.exists) {
      data['createdAt'] = DateTime.now().toIso8601String();
    }
    data['lastLogin'] = DateTime.now().toIso8601String();

    await userRef.set(data, SetOptions(merge: true));
  }

  Future<AuthResponse> updateProfile({
    String? name,
    String? surname,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResponse(error: 'No user logged in');
      }

      if (name != null || surname != null) {
        final displayName = '${name ?? ''} ${surname ?? ''}'.trim();
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (surname != null) updates['surname'] = surname;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }

      final updatedDoc =
      await _firestore.collection('users').doc(user.uid).get();
      final updatedUser = UserModel.fromMap(updatedDoc.data()!);

      return AuthResponse(user: updatedUser);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: getErrorMessage(e));
    } catch (_) {
      return AuthResponse(error: 'Failed to update profile. Please try again.');
    }
  }

  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'account-exists-with-different-credential':
        return 'Account already exists with different credentials';
      case 'invalid-credential':
        return 'Invalid credentials';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}

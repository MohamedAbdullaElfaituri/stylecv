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

  // Convert Firebase User to our UserModel
  UserModel? _userFromFirebase(User? user) {
    if (user == null) return null;

    // Split display name into name and surname
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

  // Stream of user changes
  Stream<UserModel?> get user {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      // Get additional user data from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      } else {
        // If no document exists, create one from Firebase auth data
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

  // Email & Password Sign Up
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

      // Update user profile with name
      await credential.user!.updateDisplayName('$name $surname');
      await credential.user!.reload();

      // Create user document in Firestore
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
    } catch (e) {
      return AuthResponse(error: 'An unexpected error occurred. Please try again.');
    }
  }

  // Email & Password Login
  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      await _firestore.collection('users').doc(credential.user!.uid).update({
        'lastLogin': DateTime.now().toIso8601String(),
      });

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(credential.user!.uid).get();
      final userModel = userDoc.exists
          ? UserModel.fromMap(userDoc.data()!)
          : _userFromFirebase(credential.user!);

      // If no document exists, create one
      if (!userDoc.exists && userModel != null) {
        await _createUserDocument(userModel.copyWith(
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        ));
      }

      return AuthResponse(user: userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: getErrorMessage(e));
    } catch (e) {
      return AuthResponse(error: 'An unexpected error occurred. Please try again.');
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResponse(error: 'Google sign in cancelled');
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential using OAuth
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      final uid = userCredential.user!.uid;

      // Firestore kontrolü
      final userDoc = await _firestore.collection('users').doc(uid).get();

      bool isNewUser = !userDoc.exists;

      final names = googleUser.displayName?.split(' ') ?? ['', ''];
      final userModel = UserModel(
        id: uid,
        name: names.first,
        surname: names.length > 1 ? names.sublist(1).join(' ') : '',
        email: googleUser.email,
        photoUrl: googleUser.photoUrl ?? userCredential.user!.photoURL,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      // Firestore'da kayıt yoksa oluştur
      if (isNewUser) {
        await _createUserDocument(userModel);
      } else {
        // varsa sadece son giriş zamanını güncelle
        await _firestore.collection('users').doc(uid).update({
          'lastLogin': DateTime.now().toIso8601String(),
        });
      }

      return AuthResponse(user: userModel, isNewUser: isNewUser);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: getErrorMessage(e));
    } catch (e) {
      return AuthResponse(error: 'Google sign in failed. Please try again.');
    }
  }


  // Password Reset
  Future<AuthResponse> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResponse();
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: getErrorMessage(e));
    } catch (e) {
      return AuthResponse(error: 'Failed to send reset email. Please try again.');
    }
  }

  // Sign Out
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

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Get the most up-to-date user data
    await user.reload();
    final refreshedUser = _auth.currentUser;

    // Check Firestore for additional data
    final doc = await _firestore.collection('users').doc(refreshedUser?.uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return _userFromFirebase(refreshedUser);
  }

  // Create/Update user document in Firestore
  Future<void> _createUserDocument(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }

  // Update user profile
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

      // Update Firebase Auth profile
      if (name != null || surname != null) {
        final displayName = '${name ?? ''} ${surname ?? ''}'.trim();
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      // Update Firestore document
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (surname != null) updates['surname'] = surname;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }

      // Get updated user data
      final updatedDoc = await _firestore.collection('users').doc(user.uid).get();
      final updatedUser = UserModel.fromMap(updatedDoc.data()!);

      return AuthResponse(user: updatedUser);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: getErrorMessage(e));
    } catch (e) {
      return AuthResponse(error: 'Failed to update profile. Please try again.');
    }
  }

  // Helper method to get user-friendly error messages
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
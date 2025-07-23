import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_response.dart';

@immutable
class AuthService {
  static const _googleClientId = '297188159916-0vt1j1pa4ph39inot3mcdr6pvtadv0ue.apps.googleusercontent.com';

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? (kIsWeb
            ? GoogleSignIn(clientId: _googleClientId)
            : GoogleSignIn()),
        _firestore = firestore ?? FirebaseFirestore.instance;

  static UserModel? _userFromFirebase(User? user) {
    if (user == null) return null;

    final names = user.displayName?.split(' ') ?? ['', ''];
    return UserModel(
      id: user.uid,
      name: names.first,
      surname: names.length > 1 ? names.sublist(1).join(' ') : '',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      lastLogin: DateTime.now(),
    );
  }

  Stream<UserModel?> get user => _auth.authStateChanges().asyncMap(_handleAuthChange);

  Future<UserModel?> _handleAuthChange(User? user) async {
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists
        ? UserModel.fromMap(doc.data()!)
        : await _createNewUser(user);
  }

  Future<UserModel?> _createNewUser(User user) async {
    final userModel = _userFromFirebase(user)?.copyWith(
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
    if (userModel != null) {
      await _createUserDocument(userModel);
    }
    return userModel;
  }

  Future<AuthResponse> signUpWithEmail({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
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
      return AuthResponse(error: _getErrorMessage(e));
    }
  }

  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _handleUserLogin(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: _getErrorMessage(e));
    }
  }

  Future<AuthResponse> _handleUserLogin(User user) async {
    final now = DateTime.now();
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (doc.exists) {
      await userRef.update({'lastLogin': now.toIso8601String()});
      return AuthResponse(user: UserModel.fromMap(doc.data()!));
    } else {
      final userModel = _userFromFirebase(user)?.copyWith(
        createdAt: now,
        lastLogin: now,
      );
      if (userModel != null) {
        await _createUserDocument(userModel);
      }
      return AuthResponse(user: userModel);
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      // 1. Google ile giriş yap
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResponse(error: 'Google sign in cancelled');
      }

      // 2. Kimlik bilgilerini al
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Firebase'e giriş yap
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return AuthResponse(error: 'Firebase user is null');
      }

      // 4. Kullanıcı bilgilerini hazırla
      final names = googleUser.displayName?.split(' ') ?? ['', ''];
      final photoUrl = googleUser.photoUrl ?? firebaseUser.photoURL ?? '';

      final userModel = UserModel(
        id: firebaseUser.uid,
        name: names.first,
        surname: names.length > 1 ? names.sublist(1).join(' ') : '',
        email: googleUser.email ?? firebaseUser.email ?? '',
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      // 5. Firestore'a kaydet
      await _createUserDocument(userModel);
      return AuthResponse(user: userModel);

    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: _getErrorMessage(e));
    } catch (e) {
      return AuthResponse(error: 'An unexpected error occurred');
    }
  }

  Future<AuthResponse> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResponse();
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: _getErrorMessage(e));
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    await user.reload();
    final refreshedUser = _auth.currentUser;
    final doc = await _firestore.collection('users').doc(refreshedUser?.uid).get();

    return doc.exists
        ? UserModel.fromMap(doc.data()!)
        : _userFromFirebase(refreshedUser);
  }

  Future<void> _createUserDocument(UserModel user) async {
    final data = user.toMap()
      ..['lastLogin'] = DateTime.now().toIso8601String()
      ..['createdAt'] = user.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String();

    await _firestore.collection('users').doc(user.id).set(data, SetOptions(merge: true));
  }

  Future<AuthResponse> updateProfile({
    String? name,
    String? surname,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AuthResponse(error: 'No user logged in');

      if (name != null || surname != null) {
        await user.updateDisplayName('${name ?? ''} ${surname ?? ''}'.trim());
        await user.reload();
      }

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (surname != null) updates['surname'] = surname;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }

      final updatedDoc = await _firestore.collection('users').doc(user.uid).get();
      return AuthResponse(user: UserModel.fromMap(updatedDoc.data()!));
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: _getErrorMessage(e));
    }
  }

  static String _getErrorMessage(FirebaseAuthException e) {
    const errorMessages = {
      'email-already-in-use': 'This email is already registered',
      'invalid-email': 'Please enter a valid email address',
      'operation-not-allowed': 'Email/password accounts are not enabled',
      'weak-password': 'Password is too weak (min 6 characters)',
      'user-disabled': 'This account has been disabled',
      'user-not-found': 'No account found with this email',
      'wrong-password': 'Incorrect password',
      'too-many-requests': 'Too many attempts. Try again later',
      'account-exists-with-different-credential': 'Account already exists with different credentials',
      'invalid-credential': 'Invalid credentials',
      'network-request-failed': 'Network error. Please check your connection',
    };
    return errorMessages[e.code] ?? e.message ?? 'An error occurred. Please try again.';
  }
}
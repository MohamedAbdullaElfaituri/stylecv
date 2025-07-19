import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import 'auth_response.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
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
      password: '', // Password not stored in Firebase User
      photoUrl: user.photoURL,
    );
  }

  // Stream of user changes
  Stream<UserModel?> get user {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      // Get additional user data from Firestore if needed
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return _userFromFirebase(user);
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
      await credential.user!.reload(); // Refresh user data

      // Create user document in Firestore
      final userModel = UserModel(
        id: credential.user!.uid,
        name: name,
        surname: surname,
        email: email,
        password: '', // Don't store password in Firestore
      );

      await _createUserDocument(userModel);

      return AuthResponse(user: userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: getErrorMessage(e));
    } catch (e) {
      return AuthResponse(error: e.toString());
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

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(credential.user!.uid).get();
      final userModel = userDoc.exists
          ? UserModel.fromMap(userDoc.data()!)
          : _userFromFirebase(credential.user!);

      return AuthResponse(user: userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: getErrorMessage(e));
    } catch (e) {
      return AuthResponse(error: e.toString());
    }
  }

  // Google Sign In - Fixed implementation
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Step 1: Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResponse(error: 'Google sign in cancelled');
      }

      // Step 2: Obtain auth details
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Step 3: Create credential using OAuth
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Sign in with credential
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      // Step 5: Handle new/existing user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Create new user document
        final names = googleUser.displayName?.split(' ') ?? ['', ''];
        final userModel = UserModel(
          id: userCredential.user!.uid,
          name: names.first,
          surname: names.length > 1 ? names.sublist(1).join(' ') : '',
          email: googleUser.email,
          password: '',
          photoUrl: googleUser.photoUrl,
        );

        await _createUserDocument(userModel);
        return AuthResponse(user: userModel);
      } else {
        // Existing user - get their data
        final userDoc = await _firestore.collection('users')
            .doc(userCredential.user!.uid)
            .get();

        final userModel = userDoc.exists
            ? UserModel.fromMap(userDoc.data()!)
            : _userFromFirebase(userCredential.user!);

        return AuthResponse(user: userModel);
      }
    } on FirebaseAuthException catch (e) {
      return AuthResponse(error: getErrorMessage(e));
    } catch (e, stack) {
      print('Google Sign-In Error: $e\n$stack');
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
      return AuthResponse(error: e.toString());
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Get current user
  UserModel? getCurrentUser() {
    return _userFromFirebase(_auth.currentUser);
  }

  // Create/Update user document in Firestore
  Future<void> _createUserDocument(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
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
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}
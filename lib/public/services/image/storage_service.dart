import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final ref = _storage
          .ref()
          .child('user_profile_images')
          .child('${user.uid}.jpg');

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      // Burada snackbar gibi bir context bağımlı çağrı yapılamaz.
      return null;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static Future<void> saveUserData(String uid, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(data);
  }

  static Stream<DocumentSnapshot> getUserData(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }
}
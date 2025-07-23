import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class FirestoreService {
  static const String _usersCollection = 'users'; // Sabit koleksiyon adı

  // 🔒 Private constructor to prevent instantiation
  const FirestoreService._();

  // 📌 Save user data with error handling and merge option
  static Future<void> saveUserData({
    required String uid,
    required Map<String, dynamic> data,
    bool merge = true, // Varsayılan: mevcut veriyi günceller
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(uid)
          .set(data, SetOptions(merge: merge));
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  // 📌 Get user data stream with type safety
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getUserData(String uid) {
    return FirebaseFirestore.instance
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .handleError((error) => throw _handleFirestoreError(error));
  }

  // 📌 Batch write example (for multiple operations)
  static Future<void> batchUpdateUserData({
    required String uid,
    required Map<String, dynamic> updates,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance.collection(_usersCollection).doc(uid);

    batch.update(userRef, updates);

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  // 🚨 Error handler for Firestore specific errors
  static Exception _handleFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return Exception('Permission denied. Please check security rules.');
        case 'not-found':
          return Exception('Document not found.');
        default:
          return Exception('Firestore error: ${error.message}');
      }
    }
    return Exception('Unexpected error: $error');
  }

  // 📌 Delete user data (with optional error handling)
  static Future<void> deleteUserData(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(uid)
          .delete();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }
}
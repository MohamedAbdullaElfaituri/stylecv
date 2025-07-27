import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/cv_model.dart';


class CVService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<CVModel?> loadUserCVData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('cv_data').doc(user.uid).get();

      if (doc.exists) {
        return CVModel.fromMap(doc.data()!);
      } else {
        // Yeni kullanıcı ise, sadece e-posta ile başlangıç yapılır
        return CVModel(
          email: user.email ?? '',
        );
      }
    } catch (e) {
      // Hata durumunda null dön
      return null;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../views/cv_preview.dart';
import '../views/profile_form.dart';

class ProfileCheckScreen extends StatelessWidget {
  final String uid;

  ProfileCheckScreen({required this.uid});

  Future<bool> _checkProfileExists() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('user_profiles')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkProfileExists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data!
            ? CVPreviewScreen(uid: uid)
            : ProfileFormScreen(uid: uid);
      },
    );
  }
}
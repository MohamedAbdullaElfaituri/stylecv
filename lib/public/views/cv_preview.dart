import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CVPreviewScreen extends StatelessWidget {
  final String uid;

  CVPreviewScreen({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CV Önizleme')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_profiles')
            .where('user_id', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text('Profil bulunamadı'));

          final data = docs.first.data() as Map<String, dynamic>;
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'], style: TextStyle(fontSize: 24)),
                SizedBox(height: 20),
                Text('Deneyimler:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...(data['experiences'] as List).map((exp) =>
                    ListTile(
                      title: Text(exp['title']),
                      subtitle: Text(exp['description']),
                    ),
                ).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
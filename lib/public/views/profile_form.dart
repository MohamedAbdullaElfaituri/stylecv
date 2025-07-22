import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'cv_preview.dart';

class ProfileFormScreen extends StatefulWidget {
  final String uid;

  ProfileFormScreen({required this.uid});

  @override
  _ProfileFormScreenState createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _experienceController = TextEditingController();
  List<Map<String, String>> _experiences = [];

  Future<void> _saveProfile() async {
    // Yeni koleksiyona kaydetme
    await FirebaseFirestore.instance.collection('user_profiles').add({
      'user_id': widget.uid, // Auth'dan gelen uid
      'name': _nameController.text,
      'experiences': _experiences,
      'created_at': FieldValue.serverTimestamp(),
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => CVPreviewScreen(uid: widget.uid)),
    );
  }

  void _addExperience() {
    if (_experienceController.text.isNotEmpty) {
      setState(() {
        _experiences.add({
          'title': 'İş Deneyimi ${_experiences.length + 1}',
          'description': _experienceController.text,
        });
        _experienceController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profil Oluştur')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Ad Soyad'),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _experienceController,
                decoration: InputDecoration(labelText: 'Deneyim Ekle'),
              ),
              ElevatedButton(
                onPressed: _addExperience,
                child: Text('Ekle'),
              ),
              ..._experiences.map((exp) => ListTile(
                title: Text(exp['title']!),
                subtitle: Text(exp['description']!),
              )).toList(),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
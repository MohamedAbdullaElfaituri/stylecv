import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cv_model.dart';
class CvFormPage extends StatefulWidget {
  const CvFormPage({Key? key}) : super(key: key);

  @override
  _CvFormPageState createState() => _CvFormPageState();
}

class _CvFormPageState extends State<CvFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  CVModel cvModel = CVModel();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool isSaving = false;

  // Color Scheme
  final Color _primaryColor = Color(0xFF1976D2);
  final Color _secondaryColor = Color(0xFF607D8B);
  final Color _accentColor = Color(0xFF00B0FF);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF263238);
  final Color _hintColor = Color(0xFF90A4AE);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          cvModel = CVModel.fromMap(doc.data()!);
        });
      } else {
        // Initialize with user email if new user
        cvModel.email = user.email;
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (pickedFile != null) {
        setState(() => _profileImage = File(pickedFile.path));
      }
    } on PlatformException catch (e) {
      _showSnackBar('Failed to pick image: ${e.message}');
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return null;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profile_images')
          .child('${user.uid}.jpg');

      await ref.putFile(_profileImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      _showSnackBar('Error uploading image: $e');
      return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _saveCvData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final imageUrl = await _uploadProfileImage();
      if (imageUrl != null) {
        cvModel.profileImageUrl = imageUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(cvModel.toMap(), SetOptions(merge: true));

      _showSnackBar('CV saved successfully!');
    } catch (e) {
      _showSnackBar('Error saving CV: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: _primaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
      title: Text(
        'Professional CV Builder',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    );
  }


  Widget _buildProfileImage() {
    return Center(
      child: GestureDetector(
        onTap: _pickProfileImage,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _accentColor.withOpacity(0.8),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: _profileImage != null
                ? Image.file(_profileImage!, fit: BoxFit.cover)
                : (cvModel.profileImageUrl != null
                ? Image.network(cvModel.profileImageUrl!, fit: BoxFit.cover)
                : Container(
              color: Colors.grey[200],
              child: Icon(
                Icons.camera_alt,
                size: 40,
                color: _hintColor,
              ),
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String? value,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    int? maxLines = 1,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: _textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _hintColor),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _accentColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: required
            ? (v) => v == null || v.isEmpty ? '$label is required' : null
            : validator,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateRangeField({
    required String startLabel,
    required String endLabel,
    required String? startValue,
    required String? endValue,
    required Function(String) onStartChanged,
    required Function(String) onEndChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildInputField(
            label: startLabel,
            value: startValue,
            onChanged: onStartChanged,
            keyboardType: TextInputType.datetime,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildInputField(
            label: endLabel,
            value: endValue,
            onChanged: onEndChanged,
            keyboardType: TextInputType.datetime,
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicSection({
    required String title,
    required Widget Function(int) itemBuilder,
    required VoidCallback onAdd,
    required int itemCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(title),
            FloatingActionButton.small(
              onPressed: onAdd,
              backgroundColor: _accentColor,
              child: Icon(Icons.add, color: Colors.white),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
        ...List.generate(itemCount, (index) => itemBuilder(index)),
      ],
    );
  }

  Widget _buildExperienceItem(int index) {
    if (index >= cvModel.experiences.length) return SizedBox();

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Experience #${index + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
                if (cvModel.experiences.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => cvModel.experiences.removeAt(index)),
                  ),
              ],
            ),
            SizedBox(height: 12),
            _buildInputField(
              label: 'Job Title*',
              value: cvModel.experiences[index].title,
              onChanged: (v) => cvModel.experiences[index].title = v,
              required: true,
            ),
            _buildInputField(
              label: 'Company*',
              value: cvModel.experiences[index].company,
              onChanged: (v) => cvModel.experiences[index].company = v,
              required: true,
            ),
            _buildDateRangeField(
              startLabel: 'Start Date',
              endLabel: 'End Date',
              startValue: cvModel.experiences[index].startDate,
              endValue: cvModel.experiences[index].endDate,
              onStartChanged: (v) => cvModel.experiences[index].startDate = v,
              onEndChanged: (v) => cvModel.experiences[index].endDate = v,
            ),
            _buildInputField(
              label: 'Description',
              value: cvModel.experiences[index].description,
              onChanged: (v) => cvModel.experiences[index].description = v,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationItem(int index) {
    if (index >= cvModel.education.length) return SizedBox();

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Education #${index + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
                if (cvModel.education.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => cvModel.education.removeAt(index)),
                  ),
              ],
            ),
            SizedBox(height: 12),
            _buildInputField(
              label: 'Degree*',
              value: cvModel.education[index].degree,
              onChanged: (v) => cvModel.education[index].degree = v,
              required: true,
            ),
            _buildInputField(
              label: 'Institution*',
              value: cvModel.education[index].institution,
              onChanged: (v) => cvModel.education[index].institution = v,
              required: true,
            ),
            _buildInputField(
              label: 'Field of Study',
              value: cvModel.education[index].fieldOfStudy,
              onChanged: (v) => cvModel.education[index].fieldOfStudy = v,
            ),
            _buildDateRangeField(
              startLabel: 'Start Date',
              endLabel: 'End Date',
              startValue: cvModel.education[index].startDate,
              endValue: cvModel.education[index].endDate,
              onStartChanged: (v) => cvModel.education[index].startDate = v,
              onEndChanged: (v) => cvModel.education[index].endDate = v,
            ),
            _buildInputField(
              label: 'Description',
              value: cvModel.education[index].description,
              onChanged: (v) => cvModel.education[index].description = v,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveCvData,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          shadowColor: _primaryColor.withOpacity(0.3),
        ),
        child: isSaving
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.white,
          ),
        )
            : Text(
          'SAVE CV',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: AnimatedPadding(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                _buildProfileImage(),
                SizedBox(height: 32),

                // Personal Information
                _buildSectionHeader('Personal Information'),
                _buildInputField(
                  label: 'Full Name*',
                  value: cvModel.name,
                  onChanged: (v) => cvModel.name = v,
                  required: true,
                ),
                _buildInputField(
                  label: 'Email*',
                  value: cvModel.email,
                  onChanged: (v) => cvModel.email = v,
                  keyboardType: TextInputType.emailAddress,
                  required: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter email';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    return !emailRegex.hasMatch(v) ? 'Enter valid email' : null;
                  },
                ),
                _buildInputField(
                  label: 'Phone Number',
                  value: cvModel.phone,
                  onChanged: (v) => cvModel.phone = v,
                  keyboardType: TextInputType.phone,
                ),
                _buildInputField(
                  label: 'Address',
                  value: cvModel.address,
                  onChanged: (v) => cvModel.address = v,
                ),
                SizedBox(height: 20),

                // Professional Summary
                _buildSectionHeader('Professional Summary'),
                _buildInputField(
                  label: 'Summary/About You',
                  value: cvModel.summary,
                  onChanged: (v) => cvModel.summary = v,
                  maxLines: 4,
                ),
                SizedBox(height: 20),

                // Work Experiences
                _buildDynamicSection(
                  title: 'Work Experiences',
                  itemBuilder: _buildExperienceItem,
                  onAdd: () => setState(() => cvModel.experiences.add(Experience())),
                  itemCount: cvModel.experiences.length,
                ),
                SizedBox(height: 20),

                // Education
                _buildDynamicSection(
                  title: 'Education',
                  itemBuilder: _buildEducationItem,
                  onAdd: () => setState(() => cvModel.education.add(Education())),
                  itemCount: cvModel.education.length,
                ),
                SizedBox(height: 20),

                // Certifications

                // Projects
                // Languages
                // Skills
                // (Implement similar to experiences and education)

                // Links
                _buildSectionHeader('Links'),
                _buildInputField(
                  label: 'LinkedIn URL',
                  value: cvModel.linkedIn,
                  onChanged: (v) => cvModel.linkedIn = v,
                  keyboardType: TextInputType.url,
                ),
                _buildInputField(
                  label: 'GitHub URL',
                  value: cvModel.github,
                  onChanged: (v) => cvModel.github = v,
                  keyboardType: TextInputType.url,
                ),
                _buildInputField(
                  label: 'Website URL',
                  value: cvModel.website,
                  onChanged: (v) => cvModel.website = v,
                  keyboardType: TextInputType.url,
                ),
                SizedBox(height: 30),

                // Save Button
                Center(child: _buildSaveButton()),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
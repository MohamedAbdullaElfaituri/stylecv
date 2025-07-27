import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/cv_model.dart';
import '../services/cv/cv_services.dart';
import '../services/image/image_service.dart';
import '../services/image/storage_service.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/custom_date_range_field.dart';
import '../widgets/custom_dynamic_section.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/section_header.dart';

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
  bool isSaving = false;
  DateTime? startDate;
  DateTime? endDate;
  String startDateText = '';
  String endDateText = '';

  // Color Scheme
  final Color _primaryColor = const Color(0xFF1976D2);
  final Color _accentColor = const Color(0xFF00B0FF);
  final Color _textColor = const Color(0xFF263238);
  final Color _hintColor = const Color(0xFF90A4AE);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final cvService = CVService();
    final data = await cvService.loadUserCVData();

    if (data != null && mounted) {
      setState(() {
        cvModel = data;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final imageService = ImageService();

    try {
      final image = await imageService.pickImageFromGallery();
      if (image != null && mounted) {
        setState(() => _profileImage = image);
      }
    } on PlatformException catch (e) {
      SnackbarHelper.show(context, e.message ?? 'Image selection failed');
    }
  }

  Future<void> _saveCvData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final storageService = StorageService();

      if (_profileImage != null) {
        final imageUrl = await storageService.uploadProfileImage(_profileImage!);
        if (imageUrl != null) {
          cvModel.profileImageUrl = imageUrl;
        }
      }

      await FirebaseFirestore.instance
          .collection('cv_data')
          .doc(user.uid)
          .set(cvModel.toMap(), SetOptions(merge: true));

      SnackbarHelper.show(context, 'CV saved successfully!');
    } catch (e) {
      SnackbarHelper.show(context, 'Error saving CV: $e');
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: GestureDetector(
        onTap: _pickProfileImage,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
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

  Widget _buildExperienceItem(int index, BuildContext context) {
    if (index >= cvModel.experiences.length) return const SizedBox();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => cvModel.experiences.removeAt(index)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            CustomInputField(
              label: 'Job Title*',
              value: cvModel.experiences[index].title,
              onChanged: (v) => cvModel.experiences[index].title = v,
              required: true,
            ),
            CustomInputField(
              label: 'Company*',
              value: cvModel.experiences[index].company,
              onChanged: (v) => cvModel.experiences[index].company = v,
              required: true,
            ),
            CustomDateRangeField(
              startLabel: "Start Date",
              endLabel: "End Date",
              onStartDateChanged: (DateTime? date) {
                setState(() {
                  cvModel.experiences[index].startDate = date?.toIso8601String();
                });
              },
              onEndDateChanged: (DateTime? date) {
                setState(() {
                  cvModel.experiences[index].endDate = date?.toIso8601String();
                });
              },
              initialStartDate: cvModel.experiences[index].startDate != null
                  ? DateTime.parse(cvModel.experiences[index].startDate!)
                  : null,
              initialEndDate: cvModel.experiences[index].endDate != null
                  ? DateTime.parse(cvModel.experiences[index].endDate!)
                  : null,
            ),
            CustomInputField(
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

  Widget _buildEducationItem(int index, BuildContext context) {
    if (index >= cvModel.education.length) return const SizedBox();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => cvModel.education.removeAt(index)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            CustomInputField(
              label: 'Degree*',
              value: cvModel.education[index].degree,
              onChanged: (v) => cvModel.education[index].degree = v,
              required: true,
            ),
            CustomInputField(
              label: 'Institution*',
              value: cvModel.education[index].institution,
              onChanged: (v) => cvModel.education[index].institution = v,
              required: true,
            ),
            CustomInputField(
              label: 'Field of Study',
              value: cvModel.education[index].fieldOfStudy,
              onChanged: (v) => cvModel.education[index].fieldOfStudy = v,
            ),
            CustomDateRangeField(
              startLabel: 'Start Date',
              endLabel: 'End Date',
              onStartDateChanged: (DateTime? date) {
                setState(() {
                  cvModel.education[index].startDate = date?.toIso8601String();
                });
              },
              onEndDateChanged: (DateTime? date) {
                setState(() {
                  cvModel.education[index].endDate = date?.toIso8601String();
                });
              },
              initialStartDate: cvModel.education[index].startDate != null
                  ? DateTime.parse(cvModel.education[index].startDate!)
                  : null,
              initialEndDate: cvModel.education[index].endDate != null
                  ? DateTime.parse(cvModel.education[index].endDate!)
                  : null,
            ),
            CustomInputField(
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveCvData,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          shadowColor: _primaryColor.withOpacity(0.3),
        ),
        child: isSaving
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.white,
          ),
        )
            : const Text(
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
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileImage(),
                const SizedBox(height: 32),

                SectionHeader(title: 'Personal Information', textColor: _textColor),
                CustomInputField(
                  label: 'Full Name*',
                  value: cvModel.name,
                  onChanged: (v) => cvModel.name = v,
                  required: true,
                ),
                CustomInputField(
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
                CustomInputField(
                  label: 'Phone Number',
                  value: cvModel.phone,
                  onChanged: (v) => cvModel.phone = v,
                  keyboardType: TextInputType.phone,
                ),
                CustomInputField(
                  label: 'Address',
                  value: cvModel.address,
                  onChanged: (v) => cvModel.address = v,
                ),
                const SizedBox(height: 20),

                SectionHeader(title: 'Professional Summary', textColor: _textColor),
                CustomInputField(
                  label: 'Summary/About You',
                  value: cvModel.summary,
                  onChanged: (v) => cvModel.summary = v,
                  maxLines: 4,
                ),
                const SizedBox(height: 20),

                CustomDynamicSection(
                  title: 'Work Experiences',
                  itemBuilder: _buildExperienceItem,
                  onAdd: () => setState(() => cvModel.experiences.add(Experience())),
                  itemCount: cvModel.experiences.length,
                  accentColor: _accentColor,
                  buildSectionHeader: (title, description) => SectionHeader(
                    title: title,
                    textColor: _textColor,
                  ),
                ),
                const SizedBox(height: 20),

                CustomDynamicSection(
                  title: 'Education',
                  itemBuilder: _buildEducationItem,
                  onAdd: () => setState(() => cvModel.education.add(Education())),
                  itemCount: cvModel.education.length,
                  accentColor: _accentColor,
                  buildSectionHeader: (title, description) => SectionHeader(
                    title: title,
                    textColor: _textColor,
                  ),
                ),
                const SizedBox(height: 20),

                SectionHeader(title: 'Links', textColor: _textColor),
                CustomInputField(
                  label: 'LinkedIn URL',
                  value: cvModel.linkedIn,
                  onChanged: (v) => cvModel.linkedIn = v,
                  keyboardType: TextInputType.url,
                ),
                CustomInputField(
                  label: 'GitHub URL',
                  value: cvModel.github,
                  onChanged: (v) => cvModel.github = v,
                  keyboardType: TextInputType.url,
                ),
                CustomInputField(
                  label: 'Website URL',
                  value: cvModel.website,
                  onChanged: (v) => cvModel.website = v,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 30),

                Center(child: _buildSaveButton()),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromGallery({
    int imageQuality = 85,
    double maxWidth = 800,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to pick image: ${e.message}',
      );
    }

    return null;
  }
}

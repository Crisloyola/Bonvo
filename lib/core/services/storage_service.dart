import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickProfilePhoto() =>
      _pickAndEncode(maxDimension: 300, quality: 70);

  Future<String?> pickBannerImage() =>
      _pickAndEncode(maxDimension: 800, quality: 65);

  Future<String?> _pickAndEncode({
    required int maxDimension,
    required int quality,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
      imageQuality: quality,
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    return base64Encode(bytes);
  }
}

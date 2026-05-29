import 'dart:convert';

import 'package:image_picker/image_picker.dart';

Future<String?> pickPlayerImageDataUri() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 900,
    maxHeight: 900,
    imageQuality: 82,
  );
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  final mimeType = picked.mimeType ?? _mimeTypeFromFileName(picked.name);
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

String _mimeTypeFromFileName(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

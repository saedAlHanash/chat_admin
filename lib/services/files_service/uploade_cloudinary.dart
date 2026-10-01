import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'file_uploader_base.dart';

class CloudinaryUploader implements FileUploaderBase {
  static Future<String> uploadBytes(
    Uint8List bytes, {
    required String fileName,
    String? mimeType,
    Map<String, dynamic>? customArgs,
  }) async {
    // Determine folder
    String folder = 'fitness/docs';
    final mime = mimeType ?? '';
    final ext = fileName.split('.').last.toLowerCase();

    if (mime.startsWith('image/') || ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      folder = 'fitness/images';
    } else if (mime.startsWith('video/') || ['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      folder = 'fitness/videos';
    } else if (mime.startsWith('audio/') || ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'caf'].contains(ext)) {
      folder = 'fitness/audio';
    }

    final uri = Uri.parse("https://api.cloudinary.com/v1_1/daszugczg/auto/upload");
    final request = http.MultipartRequest("POST", uri);

    request.fields['upload_preset'] = '9af17c05-74fe-43ef-bc92-87fcea258683';
    request.fields['folder'] = folder;

    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['secure_url'] ?? '';
    } else {
      throw Exception('Failed to upload file to Cloudinary: ${response.body}');
    }
  }

  @override
  Future<String> uploadFile(String filePath, {String? mimeType, Map<String, dynamic>? customArgs}) async {
    final xFile = XFile(filePath);
    final bytes = await xFile.readAsBytes();
    final name = xFile.name.isNotEmpty ? xFile.name : filePath.split('/').last;
    return uploadBytes(bytes, fileName: name, mimeType: mimeType, customArgs: customArgs);
  }
}

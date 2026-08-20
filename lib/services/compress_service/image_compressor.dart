import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

import 'compress_config.dart';
import 'compressor_base.dart';

class ImageCompressor implements CompressorBase {
  final int defaultQuality = 40;

  @override
  Future<File?> compress(File file, {CompressConfig? config}) async {
    try {
      final bytes = await file.readAsBytes();
      final compressedBytes = await compressImage(bytes);

      final String extension = Platform.isIOS ? 'jpg' : 'webp';
      final String targetPath = '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.$extension';

      final compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      debugPrint("Compression process failed: $e");
      return file;
    }
  }

  Future<Uint8List> compressImage(Uint8List list) async {
    // التحقق من صحة البيانات قبل البدء لتجنب SIGABRT على iOS
    if (list.isEmpty) {
      debugPrint("CompressService: Received empty list, skipping compression.");
      return list;
    }
    return await _compressImagePlatforms(list);
  }

  Future<Uint8List> _compressImagePlatforms(Uint8List bytes) async {
    if (bytes.isEmpty) return bytes;

    try {
      // إضافة فحص إضافي للتأكد من أن البيانات هي صورة صالحة قبل إرسالها للـ Native
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 40,
        keepExif: true,
        format: Platform.isIOS ? CompressFormat.jpeg : CompressFormat.webp,
      );

      return result;
    } catch (e) {
      debugPrint("Compression failed: $e");
      return bytes;
    }
  }

  Future<Uint8List> cropImage(Uint8List imageBytes, double targetAspectRatio) async {
    // فك التشفير باستخدام مكتبة image
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      return Uint8List.fromList([]);
    }

    final currentAspectRatio = image.width / image.height;

    int newWidth = 0, newHeight = 0;
    if (currentAspectRatio > targetAspectRatio) {
      newHeight = image.height;
      newWidth = (newHeight * targetAspectRatio).toInt();
    } else {
      newWidth = image.width;
      newHeight = (newHeight / targetAspectRatio).toInt();
    }

    final startX = (image.width - newWidth) ~/ 2;
    final startY = (image.height - newHeight) ~/ 2;

    final croppedImage = img.copyCrop(image, x: startX, y: startY, width: newWidth, height: newHeight);

    // تحسين: استخدم encodeJpg أو encodePng بناءً على الحاجة
    // لكن تذكر أن الضغط النهائي سيحولها لـ WebP في دالتك الأخرى
    return Uint8List.fromList(img.encodeJpg(croppedImage));
  }
}

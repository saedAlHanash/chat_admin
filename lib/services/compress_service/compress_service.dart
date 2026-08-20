import 'dart:io';

import 'package:mime/mime.dart';

import 'audio_compressor.dart';
import 'compress_config.dart';
import 'compressor_base.dart';
import 'image_compressor.dart';
import 'video_compressor.dart';

class CompressService {
  static CompressorBase? _getCompressor(String filePath) {
    final mimeType = lookupMimeType(filePath) ?? '';

    if (mimeType.startsWith('image/')) {
      return ImageCompressor();
    } else if (mimeType.startsWith('video/')) {
      return VideoCompressor();
    } else if (mimeType.startsWith('audio/')) {
      return AudioCompressor();
    }
    return null;
  }

  static Future<File> compressFile(File file, {CompressConfig? config}) async {
    final compressor = _getCompressor(file.path);
    if (compressor == null) return file;

    final compressedFile = await compressor.compress(file, config: config);
    return compressedFile ?? file;
  }
}

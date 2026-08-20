import 'dart:io';

import 'compress_config.dart';
import 'compressor_base.dart';

class AudioCompressor implements CompressorBase {
  @override
  Future<File?> compress(File file, {CompressConfig? config}) async {
    // TODO: Implement audio compression logic
    return file;
  }
}

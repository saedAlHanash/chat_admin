import 'dart:io';

import 'compress_config.dart';
import 'compressor_base.dart';

class VideoCompressor implements CompressorBase {
  @override
  Future<File?> compress(File file, {CompressConfig? config}) async {
    final videoConfig = config as VideoCompressConfig? ?? const VideoCompressConfig();

    // TODO: Implement video compression logic (e.g. using video_compress)
    return file;
  }
}

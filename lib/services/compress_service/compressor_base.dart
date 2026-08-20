import 'dart:io';

import 'compress_config.dart';

abstract class CompressorBase {
  Future<File?> compress(File file, {CompressConfig? config});
}

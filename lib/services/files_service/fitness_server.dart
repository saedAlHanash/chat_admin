import 'file_uploader_base.dart';

class FitnessServerUploader implements FileUploaderBase {
  @override
  Future<String> uploadFile(String filePath, {String? mimeType, Map<String, dynamic>? customArgs}) async {
    // TODO: Implement upload to your own fitness server
    throw UnimplementedError('Fitness server upload not implemented yet');
  }
}

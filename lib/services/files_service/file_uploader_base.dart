abstract class FileUploaderBase {
  Future<String> uploadFile(String filePath, {String? mimeType, Map<String, dynamic>? customArgs});
}

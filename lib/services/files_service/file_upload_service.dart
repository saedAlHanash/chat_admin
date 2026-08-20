import 'file_uploader_base.dart';
import 'fire_storage.dart';
import 'fitness_server.dart';
import 'uploade_cloudinary.dart';

enum UploadSource { cloudinary, firebase, ownServer }

class FileUploadService {
  // Config: Change this to switch globally
  static UploadSource currentSource = UploadSource.cloudinary;

  static FileUploaderBase _getUploader() {
    switch (currentSource) {
      case UploadSource.cloudinary:
        return CloudinaryUploader();
      case UploadSource.firebase:
        return FirebaseStorageUploader();
      case UploadSource.ownServer:
        return FitnessServerUploader();
    }
  }

  static Future<String> upload(String filePath, {String? mimeType, Map<String, dynamic>? customArgs}) {
    return _getUploader().uploadFile(filePath, mimeType: mimeType, customArgs: customArgs);
  }
}

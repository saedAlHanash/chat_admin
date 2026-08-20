import 'dart:io';

// import 'package:firebase_storage/firebase_storage.dart';
import 'file_uploader_base.dart';

class FirebaseStorageUploader implements FileUploaderBase {
  @override
  Future<String> uploadFile(String filePath, {String? mimeType, Map<String, dynamic>? customArgs}) async {
    final file = File(filePath);
    return '';
    // final fileName = filePath.split('/').last;
    // final ref = FirebaseStorage.instance.ref().child('uploads/$fileName');
    //
    // final uploadTask = await ref.putFile(file, SettableMetadata(contentType: mimeType));
    // return await uploadTask.ref.getDownloadURL();
  }
}

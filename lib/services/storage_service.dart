import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../core/utils/helpers.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadReportImage(File imageFile, String reportId) async {
    try {
      final extension = path.extension(imageFile.path);
      final fileName = '${reportId}_${Helpers.generateId()}$extension';
      final ref = _storage.ref().child('reports/$fileName');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/${extension.replaceAll('.', '')}'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadUserImage(File imageFile, String userId) async {
    try {
      final extension = path.extension(imageFile.path);
      final fileName = '${userId}_profile$extension';
      final ref = _storage.ref().child('users/$fileName');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/${extension.replaceAll('.', '')}'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}

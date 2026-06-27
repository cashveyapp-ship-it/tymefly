import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class MediaUploadService {
  static final _storage = FirebaseStorage.instance;
  static final _auth = FirebaseAuth.instance;
  static final _uuid = const Uuid();

  static Future<String> uploadFile(File file) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final fileId = _uuid.v4();

    final ref = _storage
        .ref()
        .child('users')
        .child(user.uid)
        .child('media')
        .child(fileId);

    final uploadTask = await ref.putFile(file);

    return uploadTask.ref.getDownloadURL();
  }
}

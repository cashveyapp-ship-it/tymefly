import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

class TymeFlyService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _storage = FirebaseStorage.instance;
  static const _uuid = Uuid();

  static Future<String?> uploadMedia({
    required File file,
    required String type,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    File uploadFile = file;

    if (type == 'video') {
      final compressed = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );

      if (compressed?.file != null) {
        uploadFile = compressed!.file!;
      }
    }

    final id = _uuid.v4();
    final ext = uploadFile.path.split('.').last;
    final ref = _storage.ref().child('users/${user.uid}/capsules/$id.$ext');

    final metadata = SettableMetadata(
      contentType: type == 'video' ? 'video/mp4' : 'image/jpeg',
    );

    final snapshot = await ref
        .putFile(uploadFile, metadata)
        .timeout(type == 'video'
            ? const Duration(minutes: 5)
            : const Duration(seconds: 45));

    if (snapshot.state != TaskState.success) {
      throw Exception('Upload failed');
    }

    return await ref.getDownloadURL().timeout(const Duration(seconds: 45));
  }

  static Future<void> createCapsule({
    required String type,
    required String message,
    required List<Map<String, dynamic>> recipients,
    required DateTime releaseDate,
    String? mediaUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final id = _uuid.v4();

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final plan = (userDoc.data()?['plan'] ?? 'free').toString();
    final isAiPlus = plan == 'ai_plus';

    String? vaultType;

    if (isAiPlus) {
      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        vaultType = 'photo_album';
      } else {
        final lowerMessage = message.toLowerCase();

        if (lowerMessage.contains('manifesto') ||
            lowerMessage.contains('legacy') ||
            lowerMessage.contains('lesson') ||
            lowerMessage.contains('values') ||
            lowerMessage.contains('belief') ||
            lowerMessage.contains('wish')) {
          vaultType = 'manifesto';
        } else {
          vaultType = 'diary';
        }
      }
    }

    await _db.collection('users').doc(user.uid).collection('capsules').doc(id).set({
      'id': id,
      'userId': user.uid,
      'type': type,
      'message': message,
      'mediaUrl': mediaUrl,
      'recipients': recipients,
      'releaseDate': Timestamp.fromDate(releaseDate),
      'status': 'scheduled',
      'emailSent': false,
      'smsSent': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isAiPlusVault': isAiPlus,
      'vaultType': vaultType,
    });

    await _db.collection('users').doc(user.uid).set({
      'freeCapsulesUsed': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updateCapsuleMessage({
    required String capsuleId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _db.collection('users').doc(user.uid).collection('capsules').doc(capsuleId).update({
      'message': message,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> rescheduleCapsule({
    required String capsuleId,
    required DateTime releaseDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _db.collection('users').doc(user.uid).collection('capsules').doc(capsuleId).update({
      'releaseDate': Timestamp.fromDate(releaseDate),
      'status': 'scheduled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> rescheduleMultipleCapsules({
    required List<String> capsuleIds,
    required DateTime releaseDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final batch = _db.batch();

    for (final capsuleId in capsuleIds) {
      final ref = _db.collection('users').doc(user.uid).collection('capsules').doc(capsuleId);

      batch.update(ref, {
        'releaseDate': Timestamp.fromDate(releaseDate),
        'status': 'scheduled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  static Future<void> deleteCapsule(String capsuleId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _db.collection('users').doc(user.uid).collection('capsules').doc(capsuleId).delete();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> userCapsules() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('capsules')
        .orderBy('releaseDate')
        .snapshots();
  }
}












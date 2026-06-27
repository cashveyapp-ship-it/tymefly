import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../widgets/tymefly_released_dialog.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> init({BuildContext? context}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();

    if (token != null && token.isNotEmpty) {
      await _db.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'notificationsEnabled': true,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _db.collection('users').doc(currentUser.uid).set({
        'fcmToken': newToken,
        'fcmTokens': FieldValue.arrayUnion([newToken]),
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    FirebaseMessaging.onMessage.listen((message) {
      if (context == null || !context.mounted) return;

      final type = message.data['type'];

      if (type == 'tymefly_released') {
        showDialog(
          context: context,
          builder: (_) => const TymeFlyReleasedDialog(),
        );
      }
    });
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'notificationsEnabled': enabled,
      'notificationsUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<bool> getNotificationsEnabled() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data();

    return data?['notificationsEnabled'] != false;
  }
}

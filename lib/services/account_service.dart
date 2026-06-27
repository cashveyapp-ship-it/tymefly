import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AccountService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> deleteAccountData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userRef = _db.collection('users').doc(user.uid);

    final capsules = await userRef.collection('capsules').get();

    for (final doc in capsules.docs) {
      final data = doc.data();
      final mediaUrl = data['mediaUrl']?.toString();

      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(mediaUrl).delete();
        } catch (_) {}
      }

      await doc.reference.delete();
    }

    final contacts = await userRef.collection('trustedContacts').get();

    for (final doc in contacts.docs) {
      await doc.reference.delete();
    }

    final purchases = await userRef.collection('purchases').get();

    for (final doc in purchases.docs) {
      await doc.reference.delete();
    }

    await userRef.delete();

    await user.delete();
  }
}


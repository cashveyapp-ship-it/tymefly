import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> createOrUpdateUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _db.collection('users').doc(user.uid);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email,
        'username': user.displayName ?? 'Friend',
        'photoUrl': user.photoURL,
        'plan': 'free',
        'freeCapsulesUsed': 0,
        'freeCapsulesLimit': 3,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        'email': user.email,
        'username': user.displayName ?? snapshot.data()?['username'] ?? 'Friend',
        'photoUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> currentUserStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    return _db.collection('users').doc(user.uid).snapshots();
  }
}

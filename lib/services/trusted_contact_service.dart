import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrustedContactService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return user.uid;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> contactsStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('trustedContacts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> addContact({
    required String name,
    required String email,
    required String phone,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanPhone = phone.trim();

    if (cleanName.isEmpty || (cleanEmail.isEmpty && cleanPhone.isEmpty)) {
      throw Exception('Add a name and either email or phone.');
    }

    final userDoc = await _db.collection('users').doc(_uid).get();
    final plan = (userDoc.data()?['plan'] ?? 'free').toString();

    final contacts = await _db
        .collection('users')
        .doc(_uid)
        .collection('trustedContacts')
        .get();

    final contactLimit = plan == 'plus'
        ? 3
        : plan == 'free'
            ? 1
            : 5;

    if (contacts.docs.length >= contactLimit) {
      throw Exception('Your $plan plan allows up to $contactLimit trusted contact${contactLimit == 1 ? '' : 's'}. Upgrade to add more.');
    }

    await _db.collection('users').doc(_uid).collection('trustedContacts').add({
      'name': cleanName,
      'email': cleanEmail,
      'phone': cleanPhone,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteContact(String contactId) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('trustedContacts')
        .doc(contactId)
        .delete();
  }
}


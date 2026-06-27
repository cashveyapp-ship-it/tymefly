import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlanService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String planFromProductId(String productId) {
    switch (productId) {
      case 'tymefly_plus_monthly':
        return 'plus';
      case 'tymefly_premium_monthly':
        return 'premium';
      case 'tymefly_legacy_monthly':
        return 'legacy';
      case 'tymefly_ai_monthly':
        return 'ai_plus';
      default:
        return 'free';
    }
  }

  static Future<void> activatePlan({
    required String productId,
    required String purchaseId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final plan = planFromProductId(productId);

    await _db.collection('users').doc(user.uid).set({
      'plan': plan,
      'activeProductId': productId,
      'lastPurchaseId': purchaseId,
      'planUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('purchases')
        .doc(purchaseId)
        .set({
      'productId': productId,
      'plan': plan,
      'purchaseId': purchaseId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    }, SetOptions(merge: true));
  }
}

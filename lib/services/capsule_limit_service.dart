import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CapsuleLimitService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static int limitForPlan(String plan) {
    switch (plan) {
      case 'plus':
        return 25;
      case 'premium':
      case 'legacy':
      case 'ai_plus':
        return -1;
      case 'free':
      default:
        return 3;
    }
  }

  static Future<void> verifyCanCreateCapsule() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final data = userDoc.data() ?? {};

    final plan = (data['plan'] ?? 'free').toString();
    final used = (data['freeCapsulesUsed'] ?? 0) as int;
    final limit = limitForPlan(plan);

    if (limit != -1 && used >= limit) {
      throw Exception('You have reached your $plan plan limit. Upgrade to create more TymeFlys.');
    }
  }
}

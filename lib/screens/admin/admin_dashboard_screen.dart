import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> setUserPlan({
    required BuildContext context,
    required String userId,
    required String plan,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'plan': plan,
      'adminOverride': true,
      'adminOverrideAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan changed to $plan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE9E9EF)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
        ),
        title: const Text('Admin Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          final users = snapshot.data?.docs ?? [];
          final totalUsers = users.length;
          final aiPlusUsers = users.where((doc) => (doc.data()['plan'] ?? '') == 'ai_plus').length;
          final freeUsers = users.where((doc) => (doc.data()['plan'] ?? 'free') == 'free').length;
          final plusUsers = users.where((doc) => (doc.data()['plan'] ?? '') == 'plus').length;
          final premiumUsers = users.where((doc) => (doc.data()['plan'] ?? '') == 'premium').length;
          final legacyUsers = users.where((doc) => (doc.data()['plan'] ?? '') == 'legacy').length;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).padding.bottom + 40,
            ),
            children: [
              const Text('TYMEFLY Admin', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Only approved admin emails can see this page.', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 20),

              _AdminCard(title: 'Total Users', value: totalUsers.toString(), icon: Icons.group_rounded),
              _AdminCard(title: 'Free Users', value: freeUsers.toString(), icon: Icons.person_outline_rounded),
              _AdminCard(title: 'Plus Users', value: plusUsers.toString(), icon: Icons.workspace_premium_rounded),
              _AdminCard(title: 'Premium Users', value: premiumUsers.toString(), icon: Icons.star_rounded),
              _AdminCard(title: 'Legacy Users', value: legacyUsers.toString(), icon: Icons.history_edu_rounded),
              _AdminCard(title: 'AI+ Users', value: aiPlusUsers.toString(), icon: Icons.auto_awesome_rounded),

              const SizedBox(height: 20),
              const Text('Recent Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),

              ...users.map((doc) {
                final data = doc.data();
                final currentPlan = (data['plan'] ?? 'free').toString();

                return Card(
                  color: Colors.white,
                  elevation: 0,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEDE7FF),
                      child: Icon(Icons.person_rounded, color: AppTheme.primary),
                    ),
                    title: Text(data['email']?.toString() ?? 'No email'),
                    subtitle: Text('Plan: $currentPlan'),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (plan) => setUserPlan(
                        context: context,
                        userId: doc.id,
                        plan: plan,
                      ),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'free', child: Text('Revoke / Set Free')),
                        PopupMenuItem(value: 'plus', child: Text('Set Plus')),
                        PopupMenuItem(value: 'premium', child: Text('Set Premium')),
                        PopupMenuItem(value: 'legacy', child: Text('Set Legacy')),
                        PopupMenuItem(value: 'ai_plus', child: Text('Set AI+')),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _AdminCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primary.withValues(alpha: .12),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}



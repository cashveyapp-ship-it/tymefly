import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/tymefly_service.dart';
import '../../services/user_profile_service.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String firstName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Friend';
    return trimmed.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: UserProfileService.currentUserStream(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data();
        final username = firstName(userData?['username'] ?? 'Friend');
        final plan = (userData?['plan'] ?? 'free').toString();
        final used = userData?['freeCapsulesUsed'] ?? 0;
        final limit = plan == 'plus'
            ? 25
            : ['premium', 'legacy', 'ai_plus'].contains(plan)
                ? 'Unlimited'
                : 3;

        final hour = DateTime.now().hour;

final greeting = hour < 12
    ? "Good morning"
    : hour < 17
        ? "Good afternoon"
        : "Good evening";

return Scaffold(
          appBar: AppBar(
            title: const Text('tymefly'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: TymeFlyService.userCapsules(),
            builder: (context, capsuleSnapshot) {
              final capsules = capsuleSnapshot.data?.docs ?? [];
              final now = DateTime.now();

              final delivered = capsules.where((doc) {
                final data = doc.data();
                final status = (data['status'] ?? '').toString();
                final releaseDate = data['releaseDate'];

                if (status == 'delivered') return true;
                if (releaseDate is Timestamp) {
                  return releaseDate.toDate().isBefore(now) || releaseDate.toDate().isAtSameMomentAs(now);
                }

                return false;
              }).length;

              final scheduled = capsules.where((doc) {
                final data = doc.data();
                final status = (data['status'] ?? '').toString();
                final releaseDate = data['releaseDate'];

                if (status != 'scheduled') return false;
                if (releaseDate is Timestamp) {
                  return releaseDate.toDate().isAfter(now);
                }

                return true;
              }).length;
              final withMedia = capsules.where((doc) => (doc.data()['mediaUrl'] ?? '').toString().isNotEmpty).length;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '$greeting, $username 👋',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Capture today. Deliver it to the future.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.secondary, AppTheme.primary, AppTheme.pink],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: .18),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 40),
                        SizedBox(height: 14),
                        Text(
                          'Create a Future Memory',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Record, upload or write something meaningful and schedule when it should be released.',
                          style: TextStyle(color: Colors.white, height: 1.45),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Scheduled',
                          value: scheduled.toString(),
                          icon: Icons.lock_clock_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Delivered',
                          value: delivered.toString(),
                          icon: Icons.mark_email_read_rounded,
                          color: AppTheme.mint,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Media',
                          value: withMedia.toString(),
                          icon: Icons.photo_library_rounded,
                          color: AppTheme.pink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Plan',
                          value: plan == 'ai_plus' ? 'AI+' : plan.toUpperCase(),
                          icon: Icons.workspace_premium_rounded,
                          color: AppTheme.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFEDE7FF)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFEDE7FF),
                          child: Icon(Icons.card_giftcard_rounded, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            limit == 'Unlimited'
                                ? 'Your $plan plan includes unlimited TymeFlys.'
                                : 'You have used $used of $limit TymeFlys.',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Recent TymeFlys',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),

                  if (capsules.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFEDE7FF)),
                      ),
                      child: const Text(
                        'No memories yet. Create your first TymeFly today.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  else
                    ...capsules.take(3).map((doc) {
                      final data = doc.data();
                      final message = (data['message'] ?? '').toString();
                      final type = (data['type'] ?? 'text').toString();

                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEDE7FF),
                            child: Icon(Icons.favorite_rounded, color: AppTheme.primary),
                          ),
                          title: Text(
                            message.isEmpty ? 'Media memory' : message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(type.toUpperCase()),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text(title, style: const TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}





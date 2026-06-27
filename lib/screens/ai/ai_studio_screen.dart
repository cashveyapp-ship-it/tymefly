import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../ai_vault/diary_screen.dart';
import '../ai_vault/manifesto_screen.dart';
import '../ai_vault/photo_album_screen.dart';
import '../subscriptions/subscription_screen.dart';

class AiStudioScreen extends StatelessWidget {
  const AiStudioScreen({super.key});

  void requireAiPlus({
    required BuildContext context,
    required bool isAiPlus,
    required VoidCallback action,
  }) {
    if (!isAiPlus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlock AI+ to access this feature.')),
      );
      return;
    }

    action();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final plan = (snapshot.data?.data()?['plan'] ?? 'free').toString();
        final isAiPlus = plan == 'ai_plus';

        return Scaffold(
          appBar: AppBar(title: const Text('AI Studio')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 42),
                    SizedBox(height: 16),
                    Text(
                      'AI Future Memories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Turn photos, videos, and text into emotional future experiences for your trusted contacts.',
                      style: TextStyle(color: Colors.white, height: 1.45),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'AI+ Vault Features',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 12),

              _VaultCard(
                icon: Icons.photo_library_rounded,
                title: 'Photo Album',
                subtitle: 'Save photos and videos into a private AI+ memory album.',
                color: AppTheme.pink,
                onTap: () {
                  requireAiPlus(
                    context: context,
                    isAiPlus: isAiPlus,
                    action: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PhotoAlbumScreen()),
                      );
                    },
                  );
                },
              ),

              _VaultCard(
                icon: Icons.menu_book_rounded,
                title: 'Manifesto',
                subtitle: 'Preserve life lessons, values, wishes, and legacy messages.',
                color: AppTheme.primary,
                onTap: () {
                  requireAiPlus(
                    context: context,
                    isAiPlus: isAiPlus,
                    action: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManifestoScreen()),
                      );
                    },
                  );
                },
              ),

              _VaultCard(
                icon: Icons.edit_note_rounded,
                title: 'Diary',
                subtitle: 'Keep private thoughts, future notes, and emotional entries.',
                color: AppTheme.mint,
                onTap: () {
                  requireAiPlus(
                    context: context,
                    isAiPlus: isAiPlus,
                    action: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DiaryScreen()),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFEDE7FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TYMEFLY AI+',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      r'$15.99/month',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Unlock Photo Album, Manifesto, Diary, AI organization, and premium future memory tools.',
                      style: TextStyle(color: AppTheme.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubscriptionScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.workspace_premium_rounded),
                        label: Text(isAiPlus ? 'AI+ Active' : 'Unlock AI+'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VaultCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _VaultCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

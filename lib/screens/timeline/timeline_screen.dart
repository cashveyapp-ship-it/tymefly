import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/tymefly_service.dart';
import 'capsule_detail_screen.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.month}/${date.day}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String countdownText(Timestamp timestamp) {
    final diff = timestamp.toDate().difference(DateTime.now());

    if (diff.isNegative) return 'Ready now';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) return '$days days, $hours hrs';
    if (hours > 0) return '$hours hrs, $minutes min';
    return '$minutes min';
  }

  IconData iconForType(String type) {
    if (type == 'photo') return Icons.image_rounded;
    if (type == 'video') return Icons.movie_rounded;
    return Icons.edit_note_rounded;
  }

  Color colorForType(String type) {
    if (type == 'photo') return AppTheme.mint;
    if (type == 'video') return AppTheme.pink;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: TymeFlyService.userCapsules(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'No TymeFlys scheduled yet.\nCreate one and it will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final type = (data['type'] ?? 'text').toString();
              final status = (data['status'] ?? 'scheduled').toString();
              final releaseDate = data['releaseDate'] as Timestamp?;
              final recipients = (data['recipients'] as List?) ?? [];
              final mediaUrl = (data['mediaUrl'] ?? '').toString();

              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CapsuleDetailScreen(capsuleId: docs[index].id, data: data),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEDE7FF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .035),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colorForType(type).withValues(alpha: .14),
                            child: Icon(iconForType(type), color: colorForType(type)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              type.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: status == 'delivered'
                                  ? AppTheme.mint.withValues(alpha: .12)
                                  : AppTheme.primary.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: status == 'delivered' ? AppTheme.mint : AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Text(
                        (data['message'] ?? '').toString().isEmpty
                            ? 'Media memory'
                            : data['message'].toString(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (mediaUrl.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F5FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_done_rounded, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  type == 'video' ? 'Video attached' : 'Photo attached',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          const Icon(Icons.group_rounded, size: 18, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            '${recipients.length} trusted contact${recipients.length == 1 ? '' : 's'}',
                            style: const TextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      if (releaseDate != null)
                        Row(
                          children: [
                            const Icon(Icons.lock_clock_rounded, size: 18, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${formatDate(releaseDate)} • ${countdownText(releaseDate)}',
                                style: const TextStyle(color: AppTheme.textMuted),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}






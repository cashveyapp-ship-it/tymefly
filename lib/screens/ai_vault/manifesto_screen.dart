import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/tymefly_service.dart';
import '../../services/ai_service.dart';
import '../timeline/capsule_detail_screen.dart';

class ManifestoScreen extends StatefulWidget {
  const ManifestoScreen({super.key});

  @override
  State<ManifestoScreen> createState() => _ManifestoScreenState();
}

class _ManifestoScreenState extends State<ManifestoScreen> {
  final selectedIds = <String>{};

  bool get selectMode => selectedIds.isNotEmpty;

  void toggleSelect(String id) {
    setState(() {
      selectedIds.contains(id) ? selectedIds.remove(id) : selectedIds.add(id);
    });
  }

  void showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label will be connected next.')),
    );
  }

  Future<void> releaseItems(List<String> ids) async {
    if (ids.isEmpty) return;

    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 30),
      initialDate: now.add(const Duration(days: 1)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null || !mounted) return;

    final releaseDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    await TymeFlyService.rescheduleMultipleCapsules(
      capsuleIds: ids,
      releaseDate: releaseDate,
    );

    if (!mounted) return;

    setState(() => selectedIds.clear());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Release date updated')),
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
        title: Text(selectMode ? '${selectedIds.length} selected' : 'Manifesto'),
        actions: [
          if (selectMode)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(() => selectedIds.clear()),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: TymeFlyService.userCapsules(),
        builder: (context, snapshot) {
          final capsules = snapshot.data?.docs ?? [];
          final manifestoItems = capsules.where((doc) {
            final message = (doc.data()['message'] ?? '').toString().toLowerCase();
            return message.contains('manifesto') ||
                message.contains('legacy') ||
                message.contains('lesson') ||
                message.contains('values') ||
                message.contains('belief') ||
                message.contains('wish');
          }).toList();

          if (manifestoItems.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'No manifesto entries yet. Create a TymeFly about your values, lessons, wishes, or legacy and it will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, height: 1.4),
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final text = manifestoItems.map((doc) {
                        final data = doc.data();
                        return data['message'] ?? '';
                      }).join('\n');

                      final summary = await AiService.summarizeAlbum(rawMessage: text);

                      if (!context.mounted) return;

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('AI Summary'),
                          content: SingleChildScrollView(child: Text(summary)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Summarize with AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: manifestoItems.length,
                  itemBuilder: (context, index) {
                    final doc = manifestoItems[index];
                    final data = doc.data();
                    final message = (data['message'] ?? '').toString();
                    final selected = selectedIds.contains(doc.id);

                    return Card(
                      color: selected ? const Color(0xFFEDE7FF) : Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      child: ListTile(
                        onLongPress: () => toggleSelect(doc.id),
                        onTap: selectMode
                            ? () => toggleSelect(doc.id)
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CapsuleDetailScreen(
                                      capsuleId: doc.id,
                                      data: data,
                                    ),
                                  ),
                                );
                              },
                        leading: CircleAvatar(
                          backgroundColor: selected ? AppTheme.primary : const Color(0xFFEDE7FF),
                          child: Icon(
                            selected ? Icons.check_rounded : Icons.menu_book_rounded,
                            color: selected ? Colors.white : AppTheme.primary,
                          ),
                        ),
                        title: Text(
                          message.isEmpty ? 'Manifesto Entry' : message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text('AI+ Manifesto'),
                      ),
                    );
                  },
                ),
              ),
              if (selectMode)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () => releaseItems(selectedIds.toList()),
                      icon: const Icon(Icons.schedule_send_rounded),
                      label: const Text('Release Selected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}














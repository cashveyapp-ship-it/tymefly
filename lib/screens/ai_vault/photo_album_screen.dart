import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../../services/tymefly_service.dart';
import '../../services/ai_service.dart';
import '../timeline/capsule_detail_screen.dart';

class PhotoAlbumScreen extends StatefulWidget {
  const PhotoAlbumScreen({super.key});

  @override
  State<PhotoAlbumScreen> createState() => _PhotoAlbumScreenState();
}

class _PhotoAlbumScreenState extends State<PhotoAlbumScreen> {
  DocumentReference<Map<String, dynamic>> _albumSummaryRef() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('ai_album')
        .doc('photo_album_summary');
  }

  Future<void> _saveAlbumSummary(String summary) async {
    await _albumSummaryRef().set({
      'summary': summary,
      'updatedAt': FieldValue.serverTimestamp(),
      'source': 'ai_album_summary',
    }, SetOptions(merge: true));
  }

  Future<void> _editAlbumSummary(String currentSummary) async {
    final controller = TextEditingController(text: currentSummary);

    final edited = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Album Summary'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Edit your album summary',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (edited == null || edited.isEmpty) return;

    await _saveAlbumSummary(edited);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Album summary updated')),
    );
  }

  final selectedIds = <String>{};
  bool selectMode = false;

  void toggleSelect(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }

      selectMode = selectedIds.isNotEmpty;
    });
  }

  void clearSelection() {
    setState(() {
      selectedIds.clear();
      selectMode = false;
    });
  }

  void showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label will be connected next.')),
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
        title: Text(selectMode ? '${selectedIds.length} selected' : 'Photo Album'),
        actions: [
          if (selectMode)
            IconButton(
              onPressed: clearSelection,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: TymeFlyService.userCapsules(),
        builder: (context, snapshot) {
          final capsules = snapshot.data?.docs ?? [];
          final mediaCapsules = capsules.where((doc) {
            final data = doc.data();
            final mediaUrl = (data['mediaUrl'] ?? '').toString();
            final type = (data['type'] ?? '').toString();
            return mediaUrl.isNotEmpty && (type == 'photo' || type == 'video');
          }).toList();

          if (mediaCapsules.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'No photos or videos yet. Create a TymeFly with media and it will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, height: 1.4),
                ),
              ),
            );
          }

          return Column(
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _albumSummaryRef().snapshots(),
                builder: (context, summarySnapshot) {
                  final summary = summarySnapshot.data?.data()?['summary']?.toString() ?? '';

                  if (summary.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFEDE7FF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text(
                                'AI Album Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            summary,
                            style: const TextStyle(height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _editAlbumSummary(summary),
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Edit Summary'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final albumText = mediaCapsules.map((doc) {
                        final data = doc.data();
                        return [
                          data['type'] ?? '',
                          data['message'] ?? '',
                          data['releaseDate']?.toString() ?? '',
                        ].join(' - ');
                      }).join('\n');

                      final summary = await AiService.summarizeAlbum(
                        rawMessage: albumText,
                      );

                      if (!context.mounted) return;

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('AI Album Summary'),
                          content: SingleChildScrollView(
                            child: Text(summary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Edit'),
                              onPressed: () async {
                                Navigator.pop(context);
                                await _editAlbumSummary(summary);
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Save To Album'),
                              onPressed: () async {
                                await _saveAlbumSummary(summary);

                                if (!context.mounted) return;

                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('AI summary saved to album'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Summarize Album with AI'),
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
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mediaCapsules.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: .72,
                  ),
                  itemBuilder: (context, index) {
                    final doc = mediaCapsules[index];
                    final data = doc.data();
                    final type = (data['type'] ?? '').toString();
                    final mediaUrl = (data['mediaUrl'] ?? '').toString();
                    final message = (data['message'] ?? '').toString();
                    final selected = selectedIds.contains(doc.id);

                    return InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        if (selectMode) {
                          toggleSelect(doc.id);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CapsuleDetailScreen(
                                capsuleId: doc.id,
                                data: data,
                              ),
                            ),
                          );
                        }
                      },
                      onLongPress: () => toggleSelect(doc.id),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: selected ? AppTheme.primary : const Color(0xFFEDE7FF),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: type == 'photo'
                                        ? Image.network(
                                            mediaUrl,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: double.infinity,
                                            color: const Color(0xFFEDE7FF),
                                            child: const Icon(
                                              Icons.play_circle_fill_rounded,
                                              size: 54,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      message.isEmpty ? type.toUpperCase() : message,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (selected)
                            const Positioned(
                              top: 10,
                              right: 10,
                              child: CircleAvatar(
                                backgroundColor: AppTheme.primary,
                                child: Icon(Icons.check_rounded, color: Colors.white),
                              ),
                            ),
                        ],
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
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showComingSoon('Release selected memories'),
                            icon: const Icon(Icons.schedule_send_rounded),
                            label: const Text('Release Selected'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => showComingSoon('Release entire album'),
                            icon: const Icon(Icons.collections_rounded),
                            label: const Text('Release Album'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
















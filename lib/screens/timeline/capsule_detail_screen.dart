import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';
import 'media_viewer_screen.dart';

class CapsuleDetailScreen extends StatelessWidget {
  final String capsuleId;
  final Map<String, dynamic> data;

  const CapsuleDetailScreen({
    super.key,
    required this.capsuleId,
    required this.data,
  });

  DocumentReference<Map<String, dynamic>> get _capsuleRef {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('capsules')
        .doc(capsuleId);
  }

  DocumentReference<Map<String, dynamic>> get _albumSummaryRef {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('ai_album')
        .doc('photo_album_summary');
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No release date';
    final date = timestamp.toDate();
    return '${date.month}/${date.day}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> editMessage(BuildContext context) async {
    final controller = TextEditingController(text: (data['message'] ?? '').toString());

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          maxLength: 1200,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    await _capsuleRef.update({
      'message': result,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message updated')),
    );
  }

  Future<void> reschedule(BuildContext context) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 30),
      initialDate: now.add(const Duration(days: 1)),
    );

    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null || !context.mounted) return;

    final releaseDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    await _capsuleRef.update({
      'releaseDate': Timestamp.fromDate(releaseDate),
      'status': 'scheduled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Release date updated')),
    );
  }

  void openMedia(BuildContext context, String mediaUrl, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaViewerScreen(
          url: mediaUrl,
          type: type,
          capsuleId: capsuleId,),
      ),
    );
  }

  Future<void> _saveAlbumSummary(String summary) async {
    await _albumSummaryRef.set({
      'summary': summary,
      'updatedAt': FieldValue.serverTimestamp(),
      'source': 'ai_album_summary',
    }, SetOptions(merge: true));
  }

  Future<void> _editAlbumSummary(BuildContext context, String currentSummary) async {
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (edited == null || edited.isEmpty) return;

    await _saveAlbumSummary(edited);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Album summary updated')),
    );
  }

  Future<void> _regenerateAlbumSummary(
    BuildContext context, {
    required String type,
    required String message,
    required dynamic releaseDate,
  }) async {
    final rawText = [type, message, releaseDate?.toString() ?? ''].join(' - ');
    final summary = await AiService.summarizeAlbum(rawMessage: rawText);

    await _saveAlbumSummary(summary);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI album summary regenerated')),
    );
  }

  Widget _buildAiAlbumSummaryCard({
    required BuildContext context,
    required String type,
    required String message,
    required dynamic releaseDate,
  }) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _albumSummaryRef.snapshots(),
      builder: (context, snapshot) {
        final summary = snapshot.data?.data()?['summary']?.toString() ?? '';

        if (summary.isEmpty) return const SizedBox.shrink();

        return _InfoCard(
          title: 'AI Album Summary',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editAlbumSummary(context, summary),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _regenerateAlbumSummary(
                        context,
                        type: type,
                        message: message,
                        releaseDate: releaseDate,
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Regenerate'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'scheduled').toString();
    final message = (data['message'] ?? '').toString();
    final type = (data['type'] ?? '').toString();
    final mediaUrl = (data['mediaUrl'] ?? '').toString();
    final releaseDate = data['releaseDate'] as Timestamp?;
    final recipients = List.from(data['recipients'] ?? []);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE9E9EF)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),
        ),
        title: const Text('TymeFly Detail'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).padding.bottom + 40,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scheduled Future Memory',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(
                  formatDate(releaseDate),
                  style: const TextStyle(color: Colors.white, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildAiAlbumSummaryCard(
            context: context,
            type: type,
            message: message,
            releaseDate: releaseDate,
          ),

          _InfoCard(
            title: 'Actions',
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => reschedule(context),
                    icon: const Icon(Icons.event_repeat_rounded),
                    label: const Text('Reschedule Release Date'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => editMessage(context),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Edit Message'),
                  ),
                ),
              ],
            ),
          ),

          _InfoCard(
            title: 'Status',
            child: Text(
              status,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary),
            ),
          ),

          if (message.isNotEmpty)
            _InfoCard(
              title: 'Message',
              child: Text(message, style: const TextStyle(height: 1.5)),
            ),

          if (mediaUrl.isNotEmpty)
            _InfoCard(
              title: 'Attached Media',
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => openMedia(context, mediaUrl, type),
                  icon: Icon(type == 'video' ? Icons.movie_rounded : Icons.image_rounded),
                  label: Text(type == 'video' ? 'Open Video' : 'Open Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),

          _InfoCard(
            title: 'Trusted Contacts',
            child: recipients.isEmpty
                ? const Text('No trusted contacts added.')
                : Column(
                    children: recipients.map((raw) {
                      final item = Map<String, dynamic>.from(raw as Map);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEDE7FF),
                          child: Icon(Icons.favorite_rounded, color: AppTheme.primary),
                        ),
                        title: Text(
                          (item['name'] ?? '').toString(),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text([
                          if ((item['email'] ?? '').toString().isNotEmpty) item['email'],
                          if ((item['phone'] ?? '').toString().isNotEmpty) item['phone'],
                        ].join(' • ')),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}







import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';

class MediaViewerScreen extends StatefulWidget {
  final String url;
  final String type;
  final String capsuleId;


  const MediaViewerScreen({
    super.key,
    required this.url,
    required this.type,
    required this.capsuleId,

  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? controller;
  bool generating = false;

  bool get isVideo => widget.type == 'video';

  String get summaryDocId {
    return base64Url.encode(utf8.encode(widget.url));
  }

  DocumentReference<Map<String, dynamic>> get summaryRef {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('capsules')
        .doc(widget.capsuleId);
  }

  @override
  void initState() {
    super.initState();

    if (isVideo) {
      controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> saveSummary(String summary) async {
    await summaryRef.set({
      'aiSummary': summary,
      'mediaUrl': widget.url,
      'type': widget.type,
      'aiSummaryUpdatedAt': FieldValue.serverTimestamp(),
      'source': 'ai_media_summary',
    }, SetOptions(merge: true));
  }

  Future<void> editSummary(String currentSummary) async {
    final controller = TextEditingController(text: currentSummary);

    final edited = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit AI Summary'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Edit the AI summary',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save'),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
          ),
        ],
      ),
    );

    if (edited == null || edited.isEmpty) return;

    await saveSummary(edited);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI summary saved to video')),
    );
  }

  Future<void> generateSummary() async {
    if (generating) return;

    setState(() => generating = true);

    try {
      final generated = await AiService.summarizeAlbum(
        rawMessage: '${widget.type} memory video/photo: ${widget.url}',
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('AI Album Summary'),
          content: SingleChildScrollView(
            child: Text(generated),
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
                await editSummary(generated);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: Text(isVideo ? 'Save To Video' : 'Save To Photo'),
              onPressed: () async {
                await saveSummary(generated);

                if (!mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isVideo
                          ? 'AI summary saved to video'
                          : 'AI summary saved to photo',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI summary failed: $e')),
      );
    } finally {
      if (mounted) setState(() => generating = false);
    }
  }

  Widget summaryCard() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: summaryRef.snapshots(),
      builder: (context, snapshot) {
        final summary = snapshot.data?.data()?['aiSummary']?.toString() ?? '';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.isEmpty ? 'No AI summary saved yet.' : summary,
                style: const TextStyle(height: 1.4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: generating ? null : generateSummary,
                  icon: generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    generating
                        ? 'Generating...'
                        : summary.isEmpty
                            ? 'Generate AI Summary'
                            : 'Regenerate AI Summary',
                  ),
                ),
              ),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => editSummary(summary),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit Saved Summary'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget mediaView() {
    if (!isVideo) {
      return InteractiveViewer(
        child: Image.network(
          widget.url,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      );
    }

    final videoController = controller;

    if (videoController == null || !videoController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: AspectRatio(
        aspectRatio: videoController.value.aspectRatio,
        child: VideoPlayer(videoController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoController = controller;

    return Scaffold(
      appBar: AppBar(
        title: Text(isVideo ? 'Video' : 'Photo'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          summaryCard(),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.62,
            child: mediaView(),
          ),
          const SizedBox(height: 90),
        ],
      ),
      floatingActionButton: isVideo && videoController != null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  videoController.value.isPlaying
                      ? videoController.pause()
                      : videoController.play();
                });
              },
              child: Icon(
                videoController.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            )
          : null,
    );
  }
}





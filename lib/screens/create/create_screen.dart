import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../services/trusted_contact_service.dart';
import '../../services/tymefly_service.dart';
import '../../services/capsule_limit_service.dart';
import '../ai/ai_future_letter_screen.dart';
import '../ai/ai_voice_narration_screen.dart';
import '../record/live_record_screen.dart';

class CreateScreen extends StatefulWidget {
  final VoidCallback? onAiPlusCreated;

  const CreateScreen({
    super.key,
    this.onAiPlusCreated,
  });

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final picker = ImagePicker();
  final messageController = TextEditingController();

  File? selectedFile;
  String type = 'text';
  DateTime? releaseDate;
  final List<Map<String, dynamic>> selectedRecipients = [];
  bool loading = false;

  static const draftMessageKey = 'tymefly_draft_message';
  static const draftTypeKey = 'tymefly_draft_type';
  static const draftReleaseKey = 'tymefly_draft_release';
  static const draftRecipientsKey = 'tymefly_draft_recipients';
  static const draftMediaPathKey = 'tymefly_draft_media_path';

  String userDraftKey(String key) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return '_';
  }

  @override
  void initState() {
    super.initState();
    loadDraft();
    messageController.addListener(saveDraft);
  }

  @override
  void dispose() {
    messageController.removeListener(saveDraft);
    messageController.dispose();
    super.dispose();
  }

  Future<void> saveDraft() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(userDraftKey(draftMessageKey), messageController.text);
    await prefs.setString(userDraftKey(draftTypeKey), type);

    if (releaseDate != null) {
      await prefs.setString(userDraftKey(draftReleaseKey), releaseDate!.toIso8601String());
    } else {
      await prefs.remove(userDraftKey(draftReleaseKey));
    }

    if (selectedFile != null) {
      await prefs.setString(userDraftKey(draftMediaPathKey), selectedFile!.path);
    } else {
      await prefs.remove(userDraftKey(draftMediaPathKey));
    }

    await prefs.setString(
      userDraftKey(draftRecipientsKey),
      jsonEncode(selectedRecipients),
    );
  }

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();

    final message = prefs.getString(userDraftKey(draftMessageKey));
    final savedType = prefs.getString(userDraftKey(draftTypeKey));
    final savedRelease = prefs.getString(userDraftKey(draftReleaseKey));
    final savedRecipients = prefs.getString(userDraftKey(draftRecipientsKey));
    final savedMediaPath = prefs.getString(userDraftKey(draftMediaPathKey));

    if (message != null) {
      messageController.text = message;
    }

    if (savedType != null) {
      type = savedType;
    }

    if (savedRelease != null) {
      releaseDate = DateTime.tryParse(savedRelease);
    }

    if (savedMediaPath != null && File(savedMediaPath).existsSync()) {
      selectedFile = File(savedMediaPath);
    }

    if (savedRecipients != null && savedRecipients.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedRecipients) as List;
        selectedRecipients
          ..clear()
          ..addAll(decoded.map((e) => Map<String, dynamic>.from(e as Map)));
      } catch (_) {
        selectedRecipients.clear();
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(userDraftKey(draftMessageKey));
    await prefs.remove(userDraftKey(draftTypeKey));
    await prefs.remove(userDraftKey(draftReleaseKey));
    await prefs.remove(userDraftKey(draftRecipientsKey));
    await prefs.remove(userDraftKey(draftMediaPathKey));
  }

  Future<void> resetDraftUi() async {
    await clearDraft();

    messageController.clear();

    setState(() {
      selectedFile = null;
      type = 'text';
      releaseDate = null;
      selectedRecipients.clear();
    });
  }

  Future<void> pickPhoto() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      selectedFile = File(picked.path);
      type = 'photo';
    });

    await saveDraft();
  }

  Future<void> pickVideo() async {
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );

    if (picked == null) return;

    setState(() {
      selectedFile = File(picked.path);
      type = 'video';
    });

    await saveDraft();
  }

  Future<void> pickReleaseDate() async {
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

    setState(() {
      releaseDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });

    await saveDraft();
  }

  Future<void> toggleContact(Map<String, dynamic> contact) async {
    final exists = selectedRecipients.any((r) => r['id'] == contact['id']);

    setState(() {
      if (exists) {
        selectedRecipients.removeWhere((r) => r['id'] == contact['id']);
      } else {
        selectedRecipients.add(contact);
      }
    });

    await saveDraft();
  }

  Future<void> scheduleTymeFly() async {
    if (messageController.text.trim().isEmpty && selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a message, photo, or video.')),
      );
      return;
    }

    if (selectedRecipients.isEmpty || releaseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select contact and release date.')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await CapsuleLimitService.verifyCanCreateCapsule();
      String? mediaUrl;

      if (selectedFile != null) {
        mediaUrl = await TymeFlyService.uploadMedia(
          file: selectedFile!,
          type: type,
        );
      }

      await TymeFlyService.createCapsule(
        type: type,
        message: messageController.text.trim(),
        recipients: selectedRecipients,
        releaseDate: releaseDate!,
        mediaUrl: mediaUrl,
      );

      if (!mounted) return;

      await clearDraft();

      messageController.clear();

      setState(() {
        selectedFile = null;
        type = 'text';
        releaseDate = null;
        selectedRecipients.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TymeFly scheduled successfully!')),
      );

      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        final plan = (userDoc.data()?['plan'] ?? 'free').toString();

        if (plan == 'ai_plus') {
          widget.onAiPlusCreated?.call();
        }
      }
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      if (errorMessage.contains('plan limit') ||
          errorMessage.contains('reached your') ||
          errorMessage.contains('Upgrade')) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Plan Limit Reached'),
            content: Text('$errorMessage\n\nPlease upgrade your plan to schedule more TymeFlys.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not schedule TymeFly: $errorMessage')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final releaseText = releaseDate == null
        ? 'Choose release date'
        : '${releaseDate!.month}/${releaseDate!.day}/${releaseDate!.year} at ${releaseDate!.hour.toString().padLeft(2, '0')}:${releaseDate!.minute.toString().padLeft(2, '0')}';

    final hasDraft = messageController.text.trim().isNotEmpty ||
        selectedFile != null ||
        releaseDate != null ||
        selectedRecipients.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Your TymeFly')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (hasDraft) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.drafts_rounded, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Draft saved. Finish scheduling when you are ready.',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: resetDraftUi,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Text(
            'Create a future memory',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add video, photo, or text. Then choose who receives it and when.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () async {
                final recordedFile = await Navigator.push<File>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LiveRecordScreen(),
                  ),
                );

                if (recordedFile != null) {
                  setState(() {
                    selectedFile = recordedFile;
                    type = 'video';
                  });

                  await saveDraft();
                }
              },
              icon: const Icon(Icons.fiber_manual_record_rounded),
              label: const Text('Record Live Video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _MediaButton(
                  icon: Icons.photo_rounded,
                  title: 'Photo',
                  color: AppTheme.mint,
                  onTap: pickPhoto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MediaButton(
                  icon: Icons.videocam_rounded,
                  title: 'Video',
                  color: AppTheme.pink,
                  onTap: pickVideo,
                ),
              ),
            ],
          ),

          if (selectedFile != null) ...[
            const SizedBox(height: 14),
            Card(
              color: Colors.white,
              elevation: 0,
              child: ListTile(
                leading: Icon(
                  type == 'photo' ? Icons.image_rounded : Icons.movie_rounded,
                  color: AppTheme.primary,
                ),
                title: Text('${type.toUpperCase()} selected'),
                subtitle: Text(selectedFile!.path.split(Platform.pathSeparator).last),
                trailing: IconButton(
                  onPressed: () async {
                    setState(() {
                      selectedFile = null;
                      type = 'text';
                    });

                    await saveDraft();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          OutlinedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const AiFutureLetterScreen()),
              );

              if (result != null && result.trim().isNotEmpty) {
                messageController.text = result.trim();
                await saveDraft();
              }
            },
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Use AI Letter'),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiVoiceNarrationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.record_voice_over_rounded),
            label: const Text('Use AI Voice Narration'),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: messageController,
            maxLines: 8,
            maxLength: 1200,
            decoration: const InputDecoration(
              labelText: 'Message optional',
              hintText: 'Write something meaningful for the future...',
            ),
          ),

          const SizedBox(height: 18),
          const Text(
            'Choose Trusted Contacts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: TrustedContactService.contactsStream(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'No saved contacts yet. Go to Trusted Contacts and add up to 5 people.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final contact = {
                    'id': doc.id,
                    'name': data['name'] ?? '',
                    'email': data['email'] ?? '',
                    'phone': data['phone'] ?? '',
                  };

                  final selected = selectedRecipients.any((r) => r['id'] == doc.id);

                  return Card(
                    color: selected ? const Color(0xFFEDE7FF) : Colors.white,
                    elevation: 0,
                    child: CheckboxListTile(
                      value: selected,
                      onChanged: (_) => toggleContact(contact),
                      title: Text(contact['name'] ?? ''),
                      subtitle: Text([
                        if ((contact['email'] ?? '').toString().isNotEmpty) contact['email'],
                        if ((contact['phone'] ?? '').toString().isNotEmpty) contact['phone'],
                      ].join(' • ')),
                      activeColor: AppTheme.primary,
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 18),
          const Text(
            'Release Date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: pickReleaseDate,
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(releaseText),
          ),

          const SizedBox(height: 12),

          if (hasDraft)
            OutlinedButton.icon(
              onPressed: resetDraftUi,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Remove Draft'),
            ),

          const SizedBox(height: 26),

          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: loading ? null : scheduleTymeFly,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Schedule TymeFly',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _MediaButton({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}




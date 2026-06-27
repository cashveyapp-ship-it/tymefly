import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';

class AiSmartStorylineScreen extends StatefulWidget {
  const AiSmartStorylineScreen({super.key});

  @override
  State<AiSmartStorylineScreen> createState() => _AiSmartStorylineScreenState();
}

class _AiSmartStorylineScreenState extends State<AiSmartStorylineScreen> {
  final controller = TextEditingController();
  bool loading = false;
  String storyline = '';

  Future<void> generateStoryline() async {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe the memory first.')),
      );
      return;
    }

    setState(() {
      loading = true;
      storyline = '';
    });

    try {
      final result = await AiService.generateSmartStoryline(
        rawMessage: controller.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        storyline = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Storyline error: $e')),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
        title: const Text('AI Smart Storyline'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Build a future storyline',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe your memory and TYMEFLY AI will organize it into a meaningful timeline/story.',
            style: TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            maxLines: 8,
            maxLength: 1200,
            decoration: const InputDecoration(
              labelText: 'Memory details',
              hintText: 'Example: This is for my daughter when she graduates...',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: loading ? null : generateStoryline,
              icon: const Icon(Icons.timeline_rounded),
              label: Text(loading ? 'Generating...' : 'Generate Storyline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
          if (storyline.isNotEmpty) ...[
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFEDE7FF)),
              ),
              child: Text(storyline, style: const TextStyle(height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }
}


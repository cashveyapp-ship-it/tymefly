import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';

class AiMemoryMovieScreen extends StatefulWidget {
  const AiMemoryMovieScreen({super.key});

  @override
  State<AiMemoryMovieScreen> createState() => _AiMemoryMovieScreenState();
}

class _AiMemoryMovieScreenState extends State<AiMemoryMovieScreen> {
  final ideaController = TextEditingController();
  bool loading = false;
  String result = '';

  Future<void> generateMovieIdea() async {
    if (ideaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe the memory first.')),
      );
      return;
    }

    setState(() {
      loading = true;
      result = '';
    });

    try {
      final moviePlan = await AiService.generateMemoryMovie(
        rawMessage: ideaController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        loading = false;
        result = moviePlan;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Movie error: ')),
      );
    }
  }

  @override
  void dispose() {
    ideaController.dispose();
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
                border: Border.all(
                  color: const Color(0xFFE9E9EF),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
              ),
            ),
          ),
        ),
        title: const Text('AI Memory Movie'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Create an AI memory movie plan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe the video, photo, or memory and TYMEFLY will shape it into a movie-style future memory.',
            style: TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 18),

          TextField(
            controller: ideaController,
            maxLines: 8,
            maxLength: 1200,
            decoration: const InputDecoration(
              labelText: 'Memory description',
              hintText: 'Example: This is a birthday video for my daughter...',
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: loading ? null : generateMovieIdea,
              icon: const Icon(Icons.movie_creation_rounded),
              label: loading
                  ? const Text('Generating...')
                  : const Text('Generate Memory Movie Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),

          if (result.isNotEmpty) ...[
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFEDE7FF)),
              ),
              child: Text(
                result,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}





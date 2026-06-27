import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';

class AiFutureLetterScreen extends StatefulWidget {
  const AiFutureLetterScreen({super.key});

  @override
  State<AiFutureLetterScreen> createState() => _AiFutureLetterScreenState();
}

class _AiFutureLetterScreenState extends State<AiFutureLetterScreen> {
  final promptController = TextEditingController();
  String generatedLetter = '';
  bool loading = false;

  Future<void> generateLetter() async {
    final rawText = promptController.text.trim();

    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write what you want the AI to help with.')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final letter = await AiService.generateFutureLetter(rawMessage: rawText);

      if (!mounted) return;

      setState(() {
        generatedLetter = letter;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI error: ')),
      );
    }
  }

  void useLetter() {
    if (generatedLetter.isEmpty) return;

    Navigator.pop(context, generatedLetter);
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
        title: const Text('AI Future Letter'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).padding.bottom + 40,
        ),
        children: [
          const Text(
            'Turn your thoughts into a future message',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Write a rough idea and TYMEFLY AI will shape it into a meaningful future letter.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 18),

          TextField(
            controller: promptController,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Your rough message',
              hintText: 'Example: Tell my daughter I am proud of her and hope she never gives up...',
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: loading ? null : generateLetter,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: loading
                  ? const Text('Creating...')
                  : const Text('Generate Future Letter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),

          if (generatedLetter.isNotEmpty) ...[
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFEDE7FF)),
              ),
              child: Text(
                generatedLetter,
                style: const TextStyle(height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: useLetter,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Use This Letter'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}







import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';

class AiVoiceNarrationScreen extends StatefulWidget {
  const AiVoiceNarrationScreen({super.key});

  @override
  State<AiVoiceNarrationScreen> createState() =>
      _AiVoiceNarrationScreenState();
}

class _AiVoiceNarrationScreenState
    extends State<AiVoiceNarrationScreen> {
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();

  bool speechEnabled = false;
  bool listening = false;
  bool generating = false;

  String spokenText = '';
  String narration = '';

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  Future<void> initSpeech() async {
    speechEnabled = await speech.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> startListening() async {
    narration = '';

    await speech.listen(
      onResult: (result) {
        setState(() {
          spokenText = result.recognizedWords;
        });
      },
    );

    setState(() {
      listening = true;
    });
  }

  Future<void> stopListening() async {
    await speech.stop();

    setState(() {
      listening = false;
    });
  }

  Future<void> generateNarration() async {
    if (spokenText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record your memory first.'),
        ),
      );
      return;
    }

    setState(() {
      generating = true;
      narration = '';
    });

    try {
      final result = await AiService.generateVoiceNarration(
        rawMessage: spokenText,
      );

      if (!mounted) return;

      setState(() {
        narration = result;
        generating = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        generating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI narration error: $e'),
        ),
      );
    }
  }

  Future<void> speakNarration() async {
    if (narration.trim().isEmpty) return;

    await tts.setSpeechRate(0.45);
    await tts.setPitch(1.0);
    await tts.speak(narration);
  }

  Future<void> stopSpeaking() async {
    await tts.stop();
  }

  @override
  void dispose() {
    tts.stop();
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
        title: const Text('AI Voice Narration'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Speak your future memory',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Record your voice and TYMEFLY AI will transform it into a heartfelt narration.',
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 40),

          Center(
            child: AvatarGlow(
              animate: listening,
              glowColor: AppTheme.primary,
              duration: const Duration(milliseconds: 2000),
              repeat: true,
              child: GestureDetector(
                onTap: () async {
                  if (!speechEnabled) return;

                  if (listening) {
                    await stopListening();
                  } else {
                    await startListening();
                  }
                },
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: AppTheme.primary,
                  child: Icon(
                    listening
                        ? Icons.mic_rounded
                        : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              listening
                  ? 'Listening... tap to stop'
                  : 'Tap microphone to record',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 28),

          if (spokenText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFEDE7FF),
                ),
              ),
              child: Text(
                spokenText,
                style: const TextStyle(height: 1.5),
              ),
            ),

          const SizedBox(height: 22),

          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed:
                  generating ? null : generateNarration,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(
                generating
                    ? 'Generating...'
                    : 'Generate AI Narration',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),

          if (narration.isNotEmpty) ...[
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFEDE7FF),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    narration,
                    style: const TextStyle(
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: speakNarration,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play Voice'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: stopSpeaking,
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('Stop'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}




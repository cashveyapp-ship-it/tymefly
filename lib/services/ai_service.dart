import 'package:cloud_functions/cloud_functions.dart';

class AiService {
  static final _functions = FirebaseFunctions.instance;

  static Future<String> generateSmartStoryline({
    required String rawMessage,
  }) async {
    final callable = _functions.httpsCallable(
      'generateSmartStoryline',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call({'rawMessage': rawMessage});
    final data = Map<String, dynamic>.from(result.data as Map);

    return data['storyline']?.toString() ?? '';
  }

  static Future<String> generateVoiceNarration({
    required String rawMessage,
  }) async {
    final callable = _functions.httpsCallable(
      'generateVoiceNarration',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call({'rawMessage': rawMessage});
    final data = Map<String, dynamic>.from(result.data as Map);

    return data['narration']?.toString() ?? '';
  }

  static Future<String> generateMemoryMovie({
    required String rawMessage,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'generateMemoryMovie',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );

      final result = await callable.call({
        'rawMessage': rawMessage,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      return data['moviePlan']?.toString() ?? '';
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<String> summarizeAlbum({
    required String rawMessage,
  }) async {
    final callable = _functions.httpsCallable(
      'summarizeAlbum',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call({'rawMessage': rawMessage});
    final data = Map<String, dynamic>.from(result.data as Map);

    return data['summary']?.toString() ?? '';
  }

  static Future<String> generateFutureLetter({
    required String rawMessage,
  }) async {
    final callable = _functions.httpsCallable('generateFutureLetter');

    final result = await callable.call({
      'rawMessage': rawMessage,
    });

    final data = Map<String, dynamic>.from(result.data as Map);

    return data['letter']?.toString() ?? '';
  }
}





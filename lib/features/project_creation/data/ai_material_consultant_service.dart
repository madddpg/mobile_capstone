import 'package:cloud_functions/cloud_functions.dart';

/// Result of one iConstruct AI consultation turn (Gemini/OpenAI via Cloud Functions).
class AiConsultResult {
  final bool success;
  final bool inScope;
  final String reply;
  final List<String> suggestions;
  final String? errorMessage;

  const AiConsultResult({
    required this.success,
    required this.inScope,
    required this.reply,
    required this.suggestions,
    this.errorMessage,
  });
}

/// Calls Firebase Cloud Functions that proxy Gemini (iConstruct-scoped only).
class AiMaterialConsultantService {
  Future<AiConsultResult> consult({
    required String projectType,
    required String userMessage,
    String style = '',
    double areaSqm = 0,
    List<String> ideaLog = const [],
    List<String> selectedMaterials = const [],
    String? projectNotes,
  }) async {
    final payload = <String, dynamic>{
      'projectType': projectType,
      'userMessage': userMessage,
      'style': style,
      'areaSqm': areaSqm,
      'ideaLog': ideaLog,
      'selectedMaterials': selectedMaterials,
      if (projectNotes != null && projectNotes.trim().isNotEmpty)
        'projectNotes': projectNotes.trim(),
    };

    // Prefer dedicated function; fall back to generateAIBOM(mode: consult)
    // when consultAIMaterials is not deployed yet (NOT_FOUND).
    try {
      return await _call('consultAIMaterials', payload);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' || e.code == 'NOT_FOUND') {
        try {
          return await _call('generateAIBOM', {
            ...payload,
            'mode': 'consult',
          });
        } on FirebaseFunctionsException catch (e2) {
          return AiConsultResult(
            success: false,
            inScope: true,
            reply: '',
            suggestions: const [],
            errorMessage: _friendlyError(e2),
          );
        }
      }
      return AiConsultResult(
        success: false,
        inScope: true,
        reply: '',
        suggestions: const [],
        errorMessage: _friendlyError(e),
      );
    } catch (e) {
      return AiConsultResult(
        success: false,
        inScope: true,
        reply: '',
        suggestions: const [],
        errorMessage: e.toString(),
      );
    }
  }

  Future<AiConsultResult> _call(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable(
      functionName,
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
    final response = await callable.call(payload);
    final data = response.data;
    if (data is! Map) {
      return const AiConsultResult(
        success: false,
        inScope: true,
        reply: '',
        suggestions: [],
        errorMessage: 'Unexpected AI response.',
      );
    }

    final map = Map<String, dynamic>.from(data);
    final rawSuggestions = map['suggestions'];
    final suggestions = <String>[];
    if (rawSuggestions is List) {
      for (final s in rawSuggestions) {
        final name = s.toString().trim();
        if (name.isNotEmpty && !suggestions.contains(name)) {
          suggestions.add(name);
        }
      }
    }

    // Older BOM-only responses won't have reply/suggestions.
    if (map.containsKey('materials') && !map.containsKey('reply')) {
      return const AiConsultResult(
        success: false,
        inScope: true,
        reply: '',
        suggestions: [],
        errorMessage:
            'AI consult mode is not deployed yet. Redeploy Firebase Functions.',
      );
    }

    final hasReply = (map['reply'] ?? '').toString().trim().isNotEmpty;
    final ok = map['success'] == true || hasReply;

    return AiConsultResult(
      success: ok,
      inScope: map['inScope'] != false,
      reply: (map['reply'] ?? '').toString().trim(),
      suggestions: suggestions.take(8).toList(),
      errorMessage: ok
          ? null
          : (map['error']?.toString() ?? 'AI returned an empty response.'),
    );
  }

  String _friendlyError(FirebaseFunctionsException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    if (code == 'not-found' || message.contains('not_found')) {
      return 'Gemini model unavailable or function missing. Redeploy functions with an updated model.';
    }
    if (code == 'internal' && message.contains('gemini')) {
      return 'GEMINI_API_KEY missing or invalid on Firebase Functions.';
    }
    if (code == 'unauthenticated') {
      return 'Please sign in again to use iConstruct AI.';
    }
    return e.message ?? e.code;
  }
}

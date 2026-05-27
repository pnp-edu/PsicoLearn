import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:psicolearn/core/services/storage_service.dart';
import 'package:psicolearn/core/di/service_locator.dart';
import 'package:psicolearn/features/personality_test/domain/models/question.dart';

class QuestionRepository {
  static const String _keyQuestionPool = 'question_pool_ids';
  static List<Question>? _cachedQuestions;

  /// Carga el banco de preguntas desde assets/data/preguntas.json (con caché)
  static Future<List<Question>> loadQuestionsFromAssets() async {
    if (_cachedQuestions != null) return _cachedQuestions!;

    try {
      final storage = sl<StorageService>();
      final blacklistedStr = storage.getStringList('blacklisted_questions') ?? [];
      final blacklistedIds = blacklistedStr.map((e) => int.parse(e)).toSet();

      final String raw = await rootBundle.loadString('assets/data/preguntas.json');
      final Map<String, dynamic> data = json.decode(raw);
      final List<dynamic> rawList = data['preguntas'] as List<dynamic>;
      
      _cachedQuestions = rawList
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .where((q) => !blacklistedIds.contains(q.id))
          .toList();
      
      return _cachedQuestions!;
    } catch (e) {
      return _fallbackQuestions();
    }
  }

  /// Gestiona el pool de preguntas para evitar repeticiones
  static Future<List<Question>> loadShuffled100Questions() async {
    final storage = sl<StorageService>();
    List<String> pool = storage.getStringList(_keyQuestionPool) ?? [];
    final allQuestions = await loadQuestionsFromAssets();
    
    if (pool.length < 10) {
      pool = allQuestions.map((q) => q.id.toString()).toList();
      pool.shuffle();
    }

    final int countToTake = pool.length >= 100 ? 100 : pool.length;
    final List<String> selectedIds = pool.sublist(0, countToTake);
    await storage.setStringList(_keyQuestionPool, pool.sublist(countToTake));

    final List<Question> selectedQuestions = [];
    for (String idStr in selectedIds) {
      final id = int.parse(idStr);
      selectedQuestions.add(allQuestions.firstWhere((q) => q.id == id, orElse: () => allQuestions[0]));
    }

    if (selectedQuestions.length < 100) {
      pool = allQuestions.map((q) => q.id.toString()).toList();
      pool.shuffle();
      final int needed = 100 - selectedQuestions.length;
      await storage.setStringList(_keyQuestionPool, pool.sublist(needed));
      for (String idStr in pool.take(needed)) {
        final id = int.parse(idStr);
        selectedQuestions.add(allQuestions.firstWhere((q) => q.id == id, orElse: () => allQuestions[0]));
      }
    }
    return selectedQuestions;
  }

  /// Obtiene una pregunta de control para una dimensión específica que no haya sido mostrada
  static Future<Question?> getControlQuestionForDimension(String dimension, Set<int> excludedIds) async {
    final all = await loadQuestionsFromAssets();
    final candidates = all.where((q) => 
      q.dimension == dimension && 
      !excludedIds.contains(q.id) &&
      q.pesoCritico >= 2.0 // Preferir preguntas con peso alto para control
    ).toList();
    
    if (candidates.isEmpty) return null;
    candidates.shuffle();
    return candidates.first;
  }

  /// Obtiene preguntas vinculadas por un ID de inconsistencia
  static Future<List<Question>> getQuestionsByInconsistencyId(String inconsistenciaId) async {
    final all = await loadQuestionsFromAssets();
    return all.where((q) => q.inconsistenciaId == inconsistenciaId).toList();
  }

  static List<Question> _fallbackQuestions() {
    return [
      Question(
        id: 1,
        text: '¿Prefieres trabajar en equipo?',
        options: {'A': 'Sí', 'B': 'A veces', 'C': 'No'},
        puntosOpciones: {'A': 10, 'B': 5, 'C': 0},
        hint: 'El trabajo en equipo es fundamental en la PNP.',
        dimension: 'Sociabilidad',
        pesoCritico: 1.0,
        tipoRiesgo: 'Aislamiento',
      ),
    ];
  }
}

import 'dart:convert';
import 'package:psicolearn/core/services/storage_service.dart';
import 'package:psicolearn/features/personality_test/domain/models/question.dart';
import 'package:psicolearn/features/personality_test/domain/models/personality_result.dart';
import 'package:psicolearn/features/personality_test/domain/logic/scoring_engine.dart';
import 'package:psicolearn/features/personality_test/data/repositories/question_repository.dart';
import 'package:psicolearn/core/di/service_locator.dart';
import 'package:psicolearn/core/services/security_service.dart';

class PersonalityTestService {
  final StorageService _storage;
  
  static const String _keyFailedQuestions = 'failed_questions';
  static const String _keyScoreFinal = 'score_final';
  static const String _keyScoreVeracidad = 'score_veracidad';
  static const String _keyAlertasRojas = 'alertas_rojas';
  static const String _keyDiagnosis = 'cached_diagnosis';
  static const String _keyScoresPorDimension = 'scores_por_dimension';
  static const String _keyTestValido = 'test_valido';
  static const String _keyHistory = 'test_history';
  static const String _keyBlacklistedQuestions = 'blacklisted_questions';
  static const String _keySeenQuestions = 'seen_questions';
  static const String _keyLastMissionDate = 'last_mission_date';
  static const String _keyAnsweredQuestionIds = 'answered_question_ids';
  static const String _keyLatencies = 'test_latencies';

  final Map<String, dynamic> _memoryCache = {};
  bool _isPersisting = false;
  int? _lastAnswerTimestamp;
  Map<int, int> _latencies = {};

  PersonalityTestService(this._storage);

  Future<List<Question>> loadQuestions() => QuestionRepository.loadQuestionsFromAssets();
  
  Future<List<Question>> loadAdaptiveShuffled100() async {
    final all = await loadQuestions();
    final blacklisted = (_storage.getStringList(_keyBlacklistedQuestions) ?? []).toSet();
    
    // Filtrar blacklisted
    final pool = all.where((q) => !blacklisted.contains(q.id.toString())).toList();
    
    // Identificar dimensiones débiles
    final scoresStr = _storage.getString(_keyScoresPorDimension);
    List<String> weakDimensions = [];
    if (scoresStr != null) {
      final Map<String, dynamic> scores = json.decode(scoresStr);
      final sorted = scores.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
      weakDimensions = sorted.take(2).map((e) => e.key).toList();
    }

    if (weakDimensions.isEmpty) {
      pool.shuffle();
      return pool.take(100).toList();
    }

    // Dividir el pool: 40% debilidades, 60% general
    final weakPool = pool.where((q) => weakDimensions.contains(q.dimension)).toList();
    final generalPool = pool.where((q) => !weakDimensions.contains(q.dimension)).toList();

    weakPool.shuffle();
    generalPool.shuffle();

    final result = [
      ...weakPool.take(40),
      ...generalPool.take(60),
    ];
    result.shuffle();
    return result;
  }

  Future<List<Question>> loadDailyMission50() async {
    final all = await loadQuestions();
    final seenIds = (_storage.getStringList(_keySeenQuestions) ?? [])
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toSet();
    
    // Si ya vimos casi todas las preguntas del banco (deja margen de 10), resetear para no quedarnos sin pool
    if (seenIds.length >= all.length - 10) {
      await _storage.removeMany([_keySeenQuestions]);
      seenIds.clear();
    }

    final List<Question> pool = all.where((q) => !seenIds.contains(q.id)).toList()..shuffle();
    
    // Acceso completo a las preguntas
    final int limit = 50;
    final List<Question> mission = pool.take(limit).toList();
    
    // Guardar como vistas
    final newSeen = seenIds.union(mission.map((q) => q.id).toSet()).map((e) => e.toString()).toList();
    await _storage.setStringList(_keySeenQuestions, newSeen);
    await _storage.setString(_keyLastMissionDate, DateTime.now().toIso8601String());

    return mission;
  }

  Future<List<Question>> loadExamSimulation110() async {
    final all = await loadQuestions();
    
    // Acceso completo a la simulación
    final int limit = 110;
    return all.toList()..shuffle()..take(limit).toList();
  }

  Future<List<Question>> loadShuffled100() => QuestionRepository.loadShuffled100Questions();

  Future<void> blacklistQuestion(int id) async {
    List<String> blacklisted = _storage.getStringList(_keyBlacklistedQuestions) ?? [];
    if (!blacklisted.contains(id.toString())) {
      blacklisted.add(id.toString());
      await _storage.setStringList(_keyBlacklistedQuestions, blacklisted);
    }
  }

  Future<List<Question>> getFailedQuestions() async {
    final failedIds = (_storage.getStringList(_keyFailedQuestions) ?? [])
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList();
    if (failedIds.isEmpty) return [];
    final all = await loadQuestions();
    return all.where((q) => failedIds.contains(q.id)).toList();
  }

  Future<void> saveAnswer(int questionId, String optionKey, List<Question> contextQuestions) async {
    // Latencia
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastAnswerTimestamp != null) {
      _latencies[questionId] = now - _lastAnswerTimestamp!;
      _storage.setString(_keyLatencies, json.encode(_latencies.map((k, v) => MapEntry(k.toString(), v))));
    }
    _lastAnswerTimestamp = now;

    // Cache y persistencia básica
    _memoryCache['answer_$questionId'] = optionKey;
    _storage.setString('answer_$questionId', optionKey);

    // Trackear como respondida para optimizar diagnóstico
    final List<String> answered = _storage.getStringList(_keyAnsweredQuestionIds) ?? [];
    if (!answered.contains(questionId.toString())) {
      answered.add(questionId.toString());
      await _storage.setStringList(_keyAnsweredQuestionIds, answered);
    }

    final question = contextQuestions.firstWhere((q) => q.id == questionId);
    final esCorrect = optionKey == question.correctAnswer;

    List<String> failures = _storage.getStringList(_keyFailedQuestions) ?? [];
    if (!esCorrect) {
      if (!failures.contains(questionId.toString())) failures.add(questionId.toString());
    } else {
      failures.remove(questionId.toString());
    }
    _storage.setStringList(_keyFailedQuestions, failures);
  }

  Future<void> syncDiagnosis() async {
    if (_isPersisting) return;
    _isPersisting = true;
    try {
      final result = await getDiagnosisResult();
      final details = result.toDetailsMap();
      
      await _storage.setString(_keyDiagnosis, details['diagnosis']);
      await _storage.setDouble(_keyScoreFinal, details['score_final']);
      await _storage.setDouble(_keyScoreVeracidad, details['score_veracidad']);
      await _storage.setBool(_keyTestValido, details['test_valido']);
      await _storage.setStringList(_keyAlertasRojas, List<String>.from(details['alertas_rojas']));
      await _storage.setString(_keyScoresPorDimension, json.encode(details['scores_por_dimension']));

      List<String> history = _storage.getStringList(_keyHistory) ?? [];
      history.add(json.encode({
        'date': DateTime.now().toIso8601String(),
        'score': details['score_final'],
      }));
      if (history.length > 20) history = history.sublist(history.length - 20);
      await _storage.setStringList(_keyHistory, history);
    } finally {
      _isPersisting = false;
    }
  }

  Future<PersonalityResult> getDiagnosisResult() async {
    final allQuestions = await loadQuestions();
    
    // Cargar latencias persistidas si están vacías en memoria
    if (_latencies.isEmpty) {
      final savedLat = _storage.getString(_keyLatencies);
      if (savedLat != null) {
        try {
          final Map<String, dynamic> decoded = json.decode(savedLat);
          _latencies = decoded.map((k, v) => MapEntry(int.parse(k), v as int));
        } catch (_) {}
      }
    }

    final List<String> answeredIds = _storage.getStringList(_keyAnsweredQuestionIds) ?? [];
    final Map<int, String> answersMap = {};
    
    for (final idStr in answeredIds) {
      final id = int.tryParse(idStr);
      if (id == null) continue;
      
      final val = _memoryCache['answer_$id'] ?? _storage.getString('answer_$id');
      if (val != null) {
        answersMap[id] = val;
        _memoryCache['answer_$id'] = val;
      }
    }
    return ScoringEngine.calculate(allQuestions, answersMap, latencies: _latencies);
  }

  Future<void> resetTest() async {
    _memoryCache.clear();
    _latencies.clear();
    final answeredIds = _storage.getStringList(_keyAnsweredQuestionIds) ?? [];
    
    final List<String> keysToRemove = [
      ...answeredIds.map((id) => 'answer_$id'),
      _keyFailedQuestions,
      _keyDiagnosis,
      _keyScoreFinal,
      _keyScoreVeracidad,
      _keyAlertasRojas,
      _keyTestValido,
      _keyScoresPorDimension,
      _keyAnsweredQuestionIds,
      _keyLatencies,
    ];
    
    await _storage.removeMany(keysToRemove);
  }

  List<Map<String, dynamic>> getHistory() {
    return (_storage.getStringList(_keyHistory) ?? []).map((e) => json.decode(e) as Map<String, dynamic>).toList();
  }
}

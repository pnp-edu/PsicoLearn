import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:psicolearn/core/services/storage_service.dart';
import 'package:psicolearn/core/di/service_locator.dart';
import 'package:psicolearn/features/interview/domain/models/interview_question.dart';

class InterviewService {
  final StorageService _storage = sl<StorageService>();
  static const String _keyMasteredQuestions = 'mastered_interview_questions';

  Future<List<InterviewQuestion>> getAvailableQuestions() async {
    final String raw = await rootBundle.loadString('assets/data/entrevista.json');
    final Map<String, dynamic> data = json.decode(raw);
    final List<dynamic> rawList = data['preguntas_entrevista'] as List<dynamic>;

    final masteredIds = _storage.getStringList(_keyMasteredQuestions) ?? [];
    
    final allQuestions = rawList
        .map((q) => InterviewQuestion.fromJson(q as Map<String, dynamic>))
        .where((q) => !masteredIds.contains(q.id.toString()))
        .toList();

    // Barajar aleatoriamente para que cada simulacro sea único
    allQuestions.shuffle();
    
    return allQuestions;
  }

  Future<void> markAsMastered(int id) async {
    final List<String> mastered = _storage.getStringList(_keyMasteredQuestions) ?? [];
    if (!mastered.contains(id.toString())) {
      mastered.add(id.toString());
      await _storage.setStringList(_keyMasteredQuestions, mastered);
    }
  }

  Future<void> resetMastery() async {
    await _storage.remove(_keyMasteredQuestions);
  }

  // Mantenemos este por compatibilidad si se usa en algún sitio
  Future<List<InterviewQuestion>> getAllQuestions() => getAvailableQuestions();
}

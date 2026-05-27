import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:psicolearn/features/interview/domain/models/interview_question.dart';

class InterviewRepository {
  static Future<List<InterviewQuestion>> loadQuestions() async {
    final String response = await rootBundle.loadString('assets/data/entrevista.json');
    final data = await json.decode(response);
    final List<dynamic> list = data['preguntas_entrevista'];
    return list.map((e) => InterviewQuestion.fromJson(e)).toList();
  }
}

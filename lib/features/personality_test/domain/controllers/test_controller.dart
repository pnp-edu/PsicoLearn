import 'package:psicolearn/core/di/service_locator.dart';
import 'package:psicolearn/features/personality_test/domain/models/question.dart';
import 'package:psicolearn/features/personality_test/domain/models/personality_result.dart';
import 'package:psicolearn/features/personality_test/domain/services/personality_test_service.dart';

class TestController {
  final List<Question> questions;
  final Map<int, String> answers = {};
  final bool isCorrectingErrors;
  final _service = sl<PersonalityTestService>();

  TestController(this.questions, {this.isCorrectingErrors = false});

  // Delegaciones al servicio para mantener compatibilidad o conveniencia
  static Future<List<Question>> loadQuestionsFromAssets() => sl<PersonalityTestService>().loadQuestions();
  static Future<List<Question>> loadShuffled100Questions() => sl<PersonalityTestService>().loadAdaptiveShuffled100();
  static Future<List<Question>> getFailedQuestions() => sl<PersonalityTestService>().getFailedQuestions();
  static Future<PersonalityResult> getDiagnosisResult() => sl<PersonalityTestService>().getDiagnosisResult();
  static Future<void> resetTest() => sl<PersonalityTestService>().resetTest();
  static List<Map<String, dynamic>> getHistory() => sl<PersonalityTestService>().getHistory();
  static Future<void> blacklistQuestion(int id) => sl<PersonalityTestService>().blacklistQuestion(id);

  Future<void> answerQuestion(int questionId, String optionKey) async {
    answers[questionId] = optionKey;
    await _service.saveAnswer(questionId, optionKey, questions);
  }

  // Métodos auxiliares para la UI si fuera necesario
  static Future<Map<String, dynamic>> getDiagnosisDetails() async {
    final result = await getDiagnosisResult();
    return result.toDetailsMap();
  }

  static Future<String> getDiagnosis() async {
    final result = await getDiagnosisResult();
    return result.diagnosis;
  }
}

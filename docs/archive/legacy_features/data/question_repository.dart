import '../domain/question.dart';

class QuestionRepository {
  const QuestionRepository();

  List<Question> loadQuestions() {
    return const [
      Question(
        id: 'q1',
        text: '¿Cómo te sientes al comenzar un nuevo proyecto?',
        options: ['Emocionado', 'Nervioso', 'Confiado', 'Indiferente'],
      ),
      Question(
        id: 'q2',
        text: '¿Prefieres trabajar en equipo o solo?',
        options: ['Equipo', 'Solo', 'Depende', 'Me adapto'],
      ),
      Question(
        id: 'q3',
        text: '¿Qué te motiva más?',
        options: ['Logros', 'Reconocimiento', 'Aprendizaje', 'Estabilidad'],
      ),
    ];
  }
}

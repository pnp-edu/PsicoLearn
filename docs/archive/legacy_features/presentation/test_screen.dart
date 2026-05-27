import 'package:flutter/material.dart';
import 'package:psicolearn/core/constants/dimensions.dart';
import 'package:psicolearn/core/widgets/glow_button.dart';
import 'package:psicolearn/core/widgets/likert_scale.dart';
import 'package:psicolearn/features/test/data/question_repository.dart';
import 'package:psicolearn/features/test/domain/question.dart';
import 'package:psicolearn/features/test/widgets/question_card.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late final List<Question> questions = QuestionRepository().loadQuestions();
  int selectedQuestionIndex = 0;
  int selectedOptionIndex = -1;

  void _nextQuestion() {
    if (selectedOptionIndex < 0) return;
    setState(() {
      selectedOptionIndex = -1;
      selectedQuestionIndex = (selectedQuestionIndex + 1).clamp(
        0,
        questions.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool finished = selectedQuestionIndex >= questions.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Test de Personalidad')),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.padding),
        child: finished
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '¡Has terminado el test!',
                      style: TextStyle(fontSize: 22, color: Colors.white),
                    ),
                    const SizedBox(height: AppDimensions.spacing),
                    const Text(
                      'Revisa tu diagnóstico en la pantalla de resultados.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuestionCard(question: questions[selectedQuestionIndex]),
                  const SizedBox(height: AppDimensions.spacing),
                  LikertScale(
                    values: questions[selectedQuestionIndex].options,
                    onSelected: (index) {
                      setState(() {
                        selectedOptionIndex = index;
                      });
                    },
                  ),
                  const Spacer(),
                  GlowButton(
                    label: finished ? 'Ver resultados' : 'Siguiente',
                    onPressed: _nextQuestion,
                  ),
                ],
              ),
      ),
    );
  }
}

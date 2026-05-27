import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/laboratory_background.dart';

import '../../../core/theme/app_theme.dart';
import 'widgets/options_selector.dart';
import '../domain/controllers/test_controller.dart';
import '../domain/logic/scoring_engine.dart';
import '../data/repositories/question_repository.dart';
import '../domain/models/question.dart';
import '../domain/services/personality_test_service.dart';
import '../../results/presentation/result_screen.dart';
import 'widgets/test_app_bar.dart';
import 'widgets/test_feedback_panel.dart';
import 'widgets/glowing_question.dart';
import 'widgets/shake_widget.dart';

class TestScreen extends StatefulWidget {
  final Future<void> Function()? onCompleted;
  final bool isCorrectingErrors;
  final bool isDailyMission;
  final bool isExamMode;

  const TestScreen({
    super.key,
    this.onCompleted,
    this.isCorrectingErrors = false,
    this.isDailyMission = false,
    this.isExamMode = false,
  });

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with TickerProviderStateMixin {
  late TestController _controller;
  List<Question>? _questionsToShow;

  int _currentIndex = 0;
  int _activeQuestionIndex = 0;
  final Set<String> _injectedDimensions = {};

  // Feedback panel state
  bool _showingFeedback = false;
  bool _lastAnswerCorrect = false;
  String _lastHint = '';
  String _lastCorrectText = '';
  Question? _lastQuestion;
  int _pendingPageIndex = 0;
  
  // Time Pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeQuestions();
    _initPulseAnimation();
  }

  void _initPulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.linear),
    );
  }

  Widget _buildQuestionSwitcher(Question question, bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ShakeWidget(
            shake: false,
            offset: 3.0,
            child: GlowingQuestion(
              key: ValueKey<int>(_currentIndex),
              text: question.text,
              color: AppTheme.accentColor,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.thumb_down_alt_rounded, color: Colors.white24, size: 20),
              tooltip: 'No me sirve esta pregunta',
              onPressed: _dislikeQuestion,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSelector(Question question) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(opacity: animation, child: SlideTransition(position: slide, child: child));
      },
      child: AbsorbPointer(
        absorbing: _showingFeedback,
        child: OptionsSelector(
          key: ValueKey<int>(_currentIndex),
          options: question.options,
          initialValue: _controller.answers[question.id],
          correctAnswer: question.correctAnswer,
          isReviewMode: widget.isCorrectingErrors,
          onChanged: (value) => _onOptionSelected(question.id, value, _currentIndex),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return AnimatedOpacity(
      opacity: _currentIndex > 0 && !_showingFeedback ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: _currentIndex > 0 && !_showingFeedback ? () => setState(() => _currentIndex--) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: AppTheme.accentColor),
              const SizedBox(width: 4),
              const Text('Anterior', style: TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReinforcementBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_rounded, color: Colors.orangeAccent, size: 16),
          SizedBox(width: 8),
          Text(
            'MODO REFUERZO: APRENDIZAJE ACTIVO',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeQuestions() async {
    final service = sl<PersonalityTestService>();
    if (widget.isCorrectingErrors) {
      _questionsToShow = await service.getFailedQuestions();
    } else if (widget.isDailyMission) {
      _questionsToShow = await service.loadDailyMission50();
    } else {
      _questionsToShow = await service.loadAdaptiveShuffled100();
    }
    _controller = TestController(
      _questionsToShow!,
      isCorrectingErrors: widget.isCorrectingErrors,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _dislikeQuestion() async {

    final question = _controller.questions[_currentIndex];
    await TestController.blacklistQuestion(question.id);

    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pregunta eliminada de tu banco local'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    if (_currentIndex < _controller.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _activeQuestionIndex = _currentIndex;
      });
    } else {
      await _showResult();
    }
  }

  // ── Lógica de preguntas ──────────────────────────────────────────────────

  Future<void> _onOptionSelected(
    int questionId,
    String optionKey,
    int pageIndex,
  ) async {
    await _controller.answerQuestion(questionId, optionKey);

    // Inyección de preguntas de control si se detectan inconsistencias
    if (_activeQuestionIndex > 5 && _activeQuestionIndex % 8 == 0) {
      _checkAndInjectControlQuestion();
    }

    final question = _questionsToShow!.firstWhere(
      (q) => q.id == questionId,
    );
    final isCorrect = optionKey == question.correctAnswer;
    
    // Vibración táctica
    if (isCorrect) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.vibrate();
    }

    setState(() {
      _lastQuestion = question;
      _lastAnswerCorrect = isCorrect;
      _lastHint = question.hint;
      _lastCorrectText = question.options[question.correctAnswer] ?? '';
      _showingFeedback = (!isCorrect || widget.isCorrectingErrors);
      _pendingPageIndex = pageIndex;
    });

    // Solo avanzar automáticamente si NO hay feedback que mostrar
    if (!_showingFeedback && isCorrect) {
      _advanceQuestion(pageIndex);
    }
  }

  void _closeFeedbackAndAdvance() {
    setState(() => _showingFeedback = false);
    // Iniciamos el avance un poco antes de que termine de bajar el panel
    // para que la nueva pregunta ya esté lista cuando el usuario vuelva a interactuar.
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _advanceQuestion(_pendingPageIndex);
    });
  }

  void _advanceQuestion(int pageIndex) {
    if (pageIndex == _activeQuestionIndex) {
      setState(() {
        _showingFeedback = false; // Reset inmediato
        if (_activeQuestionIndex < _controller.questions.length - 1) {
          _activeQuestionIndex++;
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 350), () async {
      if (!mounted) return;

      if (pageIndex == _controller.questions.length - 1 &&
          _controller.answers.length == _controller.questions.length) {
        await _showResult();
        return;
      }

      setState(() {
        _currentIndex = _activeQuestionIndex;
        _showingFeedback = false; // Reset de seguridad al cambiar de pregunta
      });
    });
  }

  Future<void> _showResult() async {
    if (widget.onCompleted != null) {
      await widget.onCompleted!();
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ResultScreen(isExamMode: false),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _checkAndInjectControlQuestion() async {
    final dimensionInDoubt = ScoringEngine.findInconsistentDimension(
      _questionsToShow!,
      _controller.answers,
    );

    if (dimensionInDoubt != null &&
        !_injectedDimensions.contains(dimensionInDoubt)) {
      final shownIds = _questionsToShow!.map((q) => q.id).toSet();
      final controlQ = await QuestionRepository.getControlQuestionForDimension(
        dimensionInDoubt,
        shownIds,
      );

      if (controlQ != null) {
        if (mounted) {
          setState(() {
            _injectedDimensions.add(dimensionInDoubt);
            _questionsToShow!.insert(_activeQuestionIndex + 1, controlQ);
          });

          // HUD sutil de recalibración
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'RECALIBRANDO: VALIDANDO ${dimensionInDoubt.toUpperCase()}...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppTheme.accentColor.withOpacity(0.9),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 20, left: 60, right: 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_questionsToShow == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentColor,
          ),
        ),
      );
    }

    if (_questionsToShow!.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                '¡Todas tus respuestas son correctas!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questionsToShow![_currentIndex];
    final progress = (_currentIndex + 1) / _questionsToShow!.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ─── Fondo de Laboratorio (Rotación 360 Grid) ─────────────────
          Positioned.fill(child: LaboratoryBackground()),

          // ─── App bar + progress ────────────────────────────────────────
          TestAppBar(
            currentIndex: _currentIndex,
            totalQuestions: _questionsToShow!.length,
            progress: progress,
            isCorrectingErrors: widget.isCorrectingErrors,
            onBackPressed: () => Navigator.of(context).pop(),
          ),

          // ─── Pregunta + opciones ──────────────────────────────────────
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      widget.isCorrectingErrors ? 80 : 56,
                      24,
                      _showingFeedback ? 260 : 24,
                    ),
                    child: Column(
                      children: [
                        if (widget.isCorrectingErrors) _buildReinforcementBadge(),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildQuestionSwitcher(question, isDark),
                                  const SizedBox(height: 24),
                                  _buildOptionsSelector(question),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBackButton(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ─── Panel de Feedback ─────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            bottom: _showingFeedback ? 0 : -500,
            left: 0,
            right: 0,
            child: _lastQuestion != null ? TestFeedbackPanel(
              isCorrect: _lastAnswerCorrect,
              correctText: _lastCorrectText,
              question: _lastQuestion!,
              onContinue: _closeFeedbackAndAdvance,
            ) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}


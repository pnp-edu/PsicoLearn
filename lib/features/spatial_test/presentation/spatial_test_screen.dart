import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/security_service.dart';
import '../domain/services/spatial_test_service.dart';
import '../domain/models/spatial_question.dart';
import 'widgets/spatial_header.dart';
import 'widgets/spatial_progress_bar.dart';
import 'widgets/spatial_question_card.dart';
import 'widgets/spatial_options_grid.dart';
import 'widgets/spatial_feedback_card.dart';

import 'package:flutter/services.dart';
import '../../../core/widgets/laboratory_background.dart';


class SpatialTestScreen extends StatefulWidget {
  final bool isReviewMode;
  const SpatialTestScreen({super.key, this.isReviewMode = false});

  @override
  State<SpatialTestScreen> createState() => _SpatialTestScreenState();
}

class _SpatialTestScreenState extends State<SpatialTestScreen>
    with TickerProviderStateMixin {
  final _service = sl<SpatialTestService>();
  late List<SpatialQuestion> _allQuestions;
  int _currentIndex = 0;
  String? _selectedOption;
  int _correctCount = 0;
  bool _answered = false;
  DateTime _questionStartTime = DateTime.now();
  final List<double> _responseTimes = [];
  
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnim;

  @override
  void initState() {
    super.initState();
    // Forzar modo horizontal al entrar
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackAnim = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.easeOutBack,
    );
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    if (widget.isReviewMode) {
      _allQuestions = await _service.getFailedQuestions();
    } else {
      _allQuestions = _service.getQuestions();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // Restaurar orientaciones al salir
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _feedbackController.dispose();
    super.dispose();
  }

  SpatialQuestion get _preguntaActual => _allQuestions[_currentIndex];

  void _onSelectOption(String option) {
    if (_answered) return;
    final isCorrect = option == _preguntaActual.correcta;
    final endTime = DateTime.now();
    _responseTimes.add(endTime.difference(_questionStartTime).inMilliseconds / 1000.0);
    
    // Vibración táctica
    if (isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _selectedOption = option;
      _answered = true;
      if (isCorrect) _correctCount++;
    });

    if (isCorrect) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _onContinue();
      });
    } else {
      // Esperar un momento mostrando el error en el grid antes de mostrar la card de patrón
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _feedbackController.forward(from: 0);
          // Registrar error para refuerzo (La Escuelita)
          _service.trackError(_preguntaActual.id);
        }
      });
    }
  }

  void _onContinue() {
    if (_currentIndex < _allQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
        _questionStartTime = DateTime.now(); // Reset tiempo
      });
      _feedbackController.reset();
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    final total = _allQuestions.length;
    final pct = (_correctCount / total * 100).round();

    // Guardar récord si no es modo repaso
    if (!widget.isReviewMode) {
      _service.setBestScore(pct);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final accentColor = pct >= 75
            ? Colors.greenAccent
            : pct >= 50
                ? Colors.amber
                : Colors.redAccent;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor:
              isDark ? const Color(0xFF161B22) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.12),
                    border: Border.all(
                        color: accentColor.withOpacity(0.4), width: 2),
                  ),
                  child: Icon(
                    pct >= 75
                        ? Icons.emoji_events_rounded
                        : Icons.psychology_rounded,
                    color: accentColor,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
                Text(
                  '$_correctCount/$total correctas',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  pct >= 75
                      ? '¡Excelente razonamiento!'
                      : pct >= 50
                          ? 'Buen intento. Sigue practicando.'
                          : 'Necesitas reforzar esta área.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'FINALIZAR',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _loadQuestions(); // Recargar para asegurar estado limpio
                    setState(() {
                      _currentIndex = 0;
                      _selectedOption = null;
                      _answered = false;
                      _correctCount = 0;
                    });
                    _feedbackController.reset();
                  },
                  child: Text(
                    'Reintentar',
                    style: TextStyle(color: accentColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_allQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.greenAccent.withOpacity(0.5)),
              const SizedBox(height: 24),
              const Text(
                '¡EXCELENTE TRABAJO!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isReviewMode ? 'No tienes errores pendientes por reforzar.' : 'No hay preguntas disponibles.',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('VOLVER AL DASHBOARD'),
              ),
            ],
          ),
        ),
      );
    }

    final total = _allQuestions.length;
    final progress = (_currentIndex + (_answered ? 1 : 0)) / total;

    return Scaffold(
      body: LaboratoryBackground(
        child: SafeArea(
          child: Column(

          children: [
            SpatialHeader(
              questionType: _preguntaActual.tipo,
              currentIndex: _currentIndex,
              totalQuestions: total,
              onBackPressed: () => Navigator.pop(context),
            ),
            SpatialProgressBar(progress: progress),
            Expanded(
              child: Row(
                children: [
                  // Lado Izquierdo: Pregunta (Zona Focalizada)
                  Expanded(
                    flex: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.015),
                        border: Border(
                          right: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                          ),
                        ),
                      ),
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: SpatialQuestionCard(
                            question: _preguntaActual,
                            index: _currentIndex,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Lado Derecho: Opciones (Zona de Acción)
                  Expanded(
                    flex: 52,
                    child: Container(
                      color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) {
                          // Efecto Slide Lateral para nueva pregunta
                          final slide = Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(position: slide, child: child),
                          );
                        },
                        child: SingleChildScrollView(
                          key: ValueKey<String>('q_${_currentIndex}'), // Cambiado para que el switcher actúe por pregunta
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Las opciones se mantienen visibles un momento si falló para ver el error
                              // Solo se ocultan cuando el panel de feedback (Análisis) está activo
                              if (_feedbackController.value == 0)
                                SpatialOptionsGrid(
                                  options: _preguntaActual.opcionesAsset,
                                  selectedOption: _selectedOption,
                                  correctOption: _preguntaActual.correcta,
                                  answered: _answered,
                                  onSelect: _onSelectOption,
                                ),
                              
                              // Si falló y el controlador de feedback avanzó, mostrar PATRÓN DETECTADO
                              AnimatedBuilder(
                                animation: _feedbackController,
                                builder: (context, child) {
                                  if (_feedbackController.value > 0) {
                                    return FadeTransition(
                                      opacity: _feedbackAnim,
                                      child: SpatialFeedbackCard(
                                        isCorrect: false,
                                        correctOption: _preguntaActual.correcta,
                                        explanation: _preguntaActual.explicacion,
                                        isLast: _currentIndex == total - 1,
                                        onContinue: _onContinue,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

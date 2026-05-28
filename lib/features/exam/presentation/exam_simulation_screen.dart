import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:psicolearn/core/di/service_locator.dart';
import 'package:psicolearn/core/services/security_service.dart';
import 'package:psicolearn/core/theme/app_theme.dart';
import 'package:psicolearn/core/widgets/laboratory_background.dart';
import 'package:psicolearn/features/personality_test/domain/models/question.dart';
import 'package:psicolearn/features/personality_test/domain/services/personality_test_service.dart';
import 'package:psicolearn/features/spatial_test/data/repositories/spatial_repository.dart';
import 'package:psicolearn/features/spatial_test/domain/models/spatial_question.dart';
import 'package:psicolearn/features/personality_test/presentation/widgets/options_selector.dart';
import 'package:psicolearn/features/personality_test/domain/logic/scoring_engine.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExamSimulationScreen extends StatefulWidget {
  const ExamSimulationScreen({super.key});

  @override
  State<ExamSimulationScreen> createState() => _ExamSimulationScreenState();
}

class _ExamSimulationScreenState extends State<ExamSimulationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Data
  List<Question> _personalityQuestions = [];
  List<SpatialQuestion> _spatialQuestions = [];
  
  // State
  final Map<int, String> _personalityAnswers = {};
  final Map<int, String> _spatialAnswers = {};
  int _currentPersonalityIndex = 0;
  int _currentSpatialIndex = 0;
  
  // Timer
  late Timer _timer;
  int _secondsRemaining = 3 * 3600; // 3 hours
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _startTimer();
  }

  Future<void> _loadData() async {
    final personalityService = sl<PersonalityTestService>();
    final pQuestions = await personalityService.loadExamSimulation110();
    final List<SpatialQuestion> sPool = List<SpatialQuestion>.from(SpatialRepository.preguntas)..shuffle();
    
    setState(() {
      _personalityQuestions = pQuestions;
      _spatialQuestions = sPool.take(40).toList();
      _isLoading = false;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer.cancel();
        _finishExam();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _finishExam() {
    _timer.cancel();
    
    // Guardar fallos en la escuelita
    final personalityService = sl<PersonalityTestService>();
    for (var q in _personalityQuestions) {
      final answer = _personalityAnswers[q.id];
      if (answer != null && answer != q.correctAnswer) {
        personalityService.saveAnswer(q.id, answer, _personalityQuestions);
      }
    }
    
    // Sincronizar diagnóstico final de forma asíncrona
    personalityService.syncDiagnosis();
    
    _showResultDialog();
  }

  Future<void> _showResultDialog() async {
    // Calcular puntaje
    final pResult = ScoringEngine.calculate(_personalityQuestions, _personalityAnswers);
    
    int sCorrect = 0;
    for (var q in _spatialQuestions) {
      if (_spatialAnswers[q.id] == q.correcta) sCorrect++;
    }
    
    bool personalityApto = pResult.diagnosis == 'APTO';
    bool spatialApto = sCorrect >= 28; // Criterio: 70% de 40
    bool examApto = personalityApto && spatialApto;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0D1117).withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: BorderSide(color: AppTheme.accentColor.withOpacity(0.3))),
          title: Center(
            child: Text(
              examApto ? '¡LOGRADO, ASPIRANTE!' : 'EXAMEN NO SUPERADO',
              style: TextStyle(
                color: examApto ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResultRow('Personalidad', personalityApto ? 'APTO' : 'INAPTO', personalityApto ? Colors.greenAccent : Colors.redAccent),
              _buildResultRow('Psicotécnico', '$sCorrect / ${_spatialQuestions.length}', spatialApto ? Colors.greenAccent : Colors.redAccent),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (examApto ? Colors.greenAccent : Colors.redAccent).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  examApto 
                    ? 'Tu perfil psicológico y capacidad cognitiva cumplen con los estándares para el ingreso.'
                    : 'Debes reforzar tus debilidades en la "Escuelita" y seguir practicando figuras.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('FINALIZAR SIMULACIÓN', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.accentColor)));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _showExitConfirmation();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: LaboratoryBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPersonalityTab(),
                      _buildSpatialTab(),
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent, width: 1.5)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('¡ALERTA DE DESERCIÓN!', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Si abandonas el examen ahora, perderás todo tu progreso. Un aspirante de élite nunca deserta de su entrenamiento crítico. ¿Estás seguro de que quieres salir?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CONTINUAR ENTRENANDO', style: TextStyle(color: Colors.cyanAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('SALIR (PERDER PROGRESO)', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white60),
            onPressed: () async {
              final bool shouldPop = await _showExitConfirmation();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          Column(
            children: [
              const Text(
                'SIMULACIÓN DE EXAMEN',
                style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12),
              ),
              Text(
                _formatTime(_secondsRemaining),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTabHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: AppTheme.accentColor.withOpacity(0.2),
        ),
        labelColor: AppTheme.accentColor,
        unselectedLabelColor: Colors.white38,
        tabs: const [
          Tab(text: 'PSICOMÉTRICO'),
          Tab(text: 'PSICOTÉCNICO'),
        ],
      ),
    );
  }

  Widget _buildPersonalityTab() {
    final q = _personalityQuestions[_currentPersonalityIndex];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'Pregunta ${_currentPersonalityIndex + 1} de ${_personalityQuestions.length}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    q.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  OptionsSelector(
                    options: q.options,
                    initialValue: _personalityAnswers[q.id],
                    onChanged: (val) {
                      setState(() => _personalityAnswers[q.id] = val);
                    },
                    correctAnswer: q.correctAnswer, 
                    isReviewMode: false,
                    isExamMode: true,
                  ),
                ],
              ),
            ),
          ),
          _buildNavigationButtons(
            onPrev: _currentPersonalityIndex > 0 ? () => setState(() => _currentPersonalityIndex--) : null,
            onNext: _currentPersonalityIndex < _personalityQuestions.length - 1 ? () => setState(() => _currentPersonalityIndex++) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSpatialTab() {
    final q = _spatialQuestions[_currentSpatialIndex];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'Figura ${_currentSpatialIndex + 1} de ${_spatialQuestions.length}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    q.titulo,
                    style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    q.instruccion,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 220,
                    child: SvgPicture.asset(q.secuenciaAsset, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: q.opcionesAsset.entries.map((entry) {
                      bool selected = _spatialAnswers[q.id] == entry.key;
                      return GestureDetector(
                        onTap: () => setState(() => _spatialAnswers[q.id] = entry.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 90,
                          height: 110,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.accentColor.withOpacity(0.15) : Colors.white.withOpacity(0.03),
                            border: Border.all(
                              color: selected ? AppTheme.accentColor : Colors.white.withOpacity(0.1),
                              width: selected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: selected ? [
                              BoxShadow(color: AppTheme.accentColor.withOpacity(0.2), blurRadius: 10)
                            ] : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  color: selected ? AppTheme.accentColor : Colors.white60,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SvgPicture.asset(
                                  entry.value,
                                  fit: BoxFit.contain,
                                  placeholderBuilder: (context) => const Center(
                                    child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          _buildNavigationButtons(
            onPrev: _currentSpatialIndex > 0 ? () => setState(() => _currentSpatialIndex--) : null,
            onNext: _currentSpatialIndex < _spatialQuestions.length - 1 ? () => setState(() => _currentSpatialIndex++) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons({VoidCallback? onPrev, VoidCallback? onNext}) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavBtn(Icons.arrow_back_ios_new_rounded, 'ANTERIOR', onPrev),
          _buildNavBtn(Icons.arrow_forward_ios_rounded, 'SIGUIENTE', onNext, isNext: true),
        ],
      ),
    );
  }

  Widget _buildNavBtn(IconData icon, String label, VoidCallback? onTap, {bool isNext = false}) {
    return Opacity(
      opacity: onTap != null ? 1.0 : 0.3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              if (!isNext) Icon(icon, size: 16, color: Colors.white70),
              if (!isNext) const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
              if (isNext) const SizedBox(width: 8),
              if (isNext) Icon(icon, size: 16, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    int totalAnswered = _personalityAnswers.length + _spatialAnswers.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('PROGRESO TOTAL', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: totalAnswered / 150,
                  backgroundColor: Colors.white10,
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: totalAnswered > 0 ? _finishExam : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('FINALIZAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

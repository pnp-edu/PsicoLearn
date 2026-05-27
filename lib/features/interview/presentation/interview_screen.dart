import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:psicolearn/core/di/service_locator.dart';
import 'package:psicolearn/core/services/storage_service.dart';
import 'package:psicolearn/features/interview/domain/models/interview_question.dart';
import 'package:psicolearn/features/interview/domain/services/interview_service.dart';
import 'package:psicolearn/core/theme/app_theme.dart';
import '../../../core/widgets/laboratory_background.dart';


class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final InterviewService _service = sl<InterviewService>();
  final StorageService _storage = sl<StorageService>();
  
  List<InterviewQuestion> _questions = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = true;

  // Realism Mode Vars
  bool _isRealismMode = false;
  Timer? _countdownTimer;
  double _timerProgress = 1.0;
  int _sessionQuestionsAnswered = 0;
  int _sessionMastered = 0;
  int _sessionTimeouts = 0;

  @override
  void initState() {
    super.initState();
    _isRealismMode = _storage.getBool('interview_realism_mode') ?? false;
    _loadQuestions();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final q = await _service.getAvailableQuestions();
    if (mounted) {
      setState(() {
        _questions = q;
        _isLoading = false;
        _currentIndex = 0;
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      _startTimer();
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    if (!_isRealismMode || _questions.isEmpty || _showAnswer) return;

    setState(() => _timerProgress = 1.0);
    const duration = Duration(seconds: 4);
    final startTime = DateTime.now();

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final elapsed = DateTime.now().difference(startTime);
      final remaining = duration.inMilliseconds - elapsed.inMilliseconds;
      
      if (remaining <= 0) {
        timer.cancel();
        _handleTimeout();
      } else {
        setState(() {
          _timerProgress = remaining / duration.inMilliseconds;
        });
        // Vibrar en los últimos 1.5 segundos
        if (remaining < 1500 && remaining % 200 < 50) {
          HapticFeedback.lightImpact();
        }
      }
    });
  }

  void _handleTimeout() {
    if (!mounted) return;
    HapticFeedback.vibrate();
    _sessionTimeouts++;
    _sessionQuestionsAnswered++;
    _checkBatchOrNext();
  }

  void _checkBatchOrNext() {
    if (_sessionQuestionsAnswered % 7 == 0 && _sessionQuestionsAnswered > 0) {
      _showBatchDialog();
    } else {
      _nextQuestion();
    }
  }

  void _showBatchDialog() {
    _countdownTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('CORTE DE EVALUACIÓN', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _batchStat('Preguntas vistas', '$_sessionQuestionsAnswered'),
            _batchStat('Dominadas', '$_sessionMastered'),
            _batchStat('Sin respuesta', '$_sessionTimeouts'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalResults();
            },
            child: const Text('VER RESULTADOS', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _nextQuestion();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.black),
            child: const Text('CONTINUAR'),
          ),
        ],
      ),
    );
  }

  Widget _batchStat(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  void _showFinalResults() {
    _countdownTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => _ResultsSummaryScreen(
        total: _sessionQuestionsAnswered,
        mastered: _sessionMastered,
        timeouts: _sessionTimeouts,
      )),
    );
  }

  Future<void> _markMastered(int id) async {
    _countdownTimer?.cancel();
    _sessionMastered++;
    _sessionQuestionsAnswered++;
    await _service.markAsMastered(id);
    if (_questions.length <= 1) {
      _showFinalResults();
    } else {
      _checkBatchOrNext();
    }
  }

  void _nextQuestion() {
    _countdownTimer?.cancel();
    if (_currentIndex < _questions.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOutQuart);
    } else {
      setState(() => _isLoading = true);
      _loadQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () {
            if (_sessionQuestionsAnswered > 0) {
              _showFinalResults();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('SIMULADOR TÁCTICO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2.0)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: LaboratoryBackground()),
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
            : _questions.isEmpty 
              ? _buildAllMasteredState(isDark)
              : SafeArea(
                  child: Column(
                    children: [
                      if (_isRealismMode) _buildRealismTimer(),
                      _buildProgressHeader(),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (idx) => setState(() {
                            _currentIndex = idx;
                            _showAnswer = false;
                            _startTimer();
                          }),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) => _buildQuestionView(_questions[index], isDark),
                        ),
                      ),
                      _buildTacticalControls(isDark),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildRealismTimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_rounded, size: 14, color: _timerProgress < 0.3 ? Colors.redAccent : Colors.purpleAccent),
              const SizedBox(width: 6),
              Text('TIEMPO DE REACCIÓN', 
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _timerProgress < 0.3 ? Colors.redAccent : Colors.purpleAccent)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _timerProgress,
              minHeight: 3,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(_timerProgress < 0.3 ? Colors.redAccent : Colors.purpleAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 15, 30, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('SIMULACRO ACTIVO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppTheme.accentColor)),
          Text('${_currentIndex + 1} / ${_questions.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuestionView(InterviewQuestion q, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
            ),
            child: Text(q.categoria, style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Text(q.pregunta, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.4, color: isDark ? Colors.white : Colors.black87)),
          ),
          const SizedBox(height: 30),
          if (!_showAnswer)
            ElevatedButton.icon(
              onPressed: () {
                _countdownTimer?.cancel();
                setState(() => _showAnswer = true);
              },
              icon: const Icon(Icons.psychology_alt_rounded),
              label: const Text('¿CÓMO RESPONDER?', style: TextStyle(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor, foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          if (_showAnswer) ...[
            _buildInfoCard('ENFOQUE TÁCTICO', q.puntosClave, Colors.amber, isDark),
            const SizedBox(height: 16),
            _buildInfoCard('LENGUAJE NATURAL', q.respuestaIdeal, Colors.greenAccent, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTacticalControls(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _sessionQuestionsAnswered++;
                _checkBatchOrNext();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('MÁS ADELANTE', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _markMastered(_questions[_currentIndex].id),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white10 : Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('LO TENGO ✓', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllMasteredState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_rounded, size: 100, color: Colors.greenAccent),
            const SizedBox(height: 24),
            Text('¡BANCO DOMINADO!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('VOLVER AL DASHBOARD')),
          ],
        ),
      ),
    );
  }
}

class _ResultsSummaryScreen extends StatelessWidget {
  final int total;
  final int mastered;
  final int timeouts;

  const _ResultsSummaryScreen({required this.total, required this.mastered, required this.timeouts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('RESULTADOS DE SESIÓN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _resultRow('Preguntas en sesión', '$total', Colors.blueAccent),
              _resultRow('Dominadas (Aprendido)', '$mastered', Colors.greenAccent),
              _resultRow('Sin respuesta (Timeout)', '$timeouts', Colors.redAccent),
              _resultRow('Saltadas', '${total - mastered - timeouts}', Colors.amber),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 60)),
                child: const Text('FINALIZAR ENTRENAMIENTO', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String val, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      ],
    ),
  );
}

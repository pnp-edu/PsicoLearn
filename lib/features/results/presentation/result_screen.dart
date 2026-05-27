import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../personality_test/domain/logic/scoring_engine.dart';
import '../../personality_test/domain/controllers/test_controller.dart';
import '../../personality_test/domain/models/personality_result.dart';
import 'widgets/result_header.dart';
import 'widgets/result_alerts.dart';
import 'widgets/result_stat_cards.dart';

import 'widgets/history_chart.dart';
import '../../../core/widgets/laboratory_background.dart';


class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, bool isExamMode = false});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late Future<PersonalityResult> _resultFuture;
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _resultFuture = TestController.getDiagnosisResult();

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOutSine),
    );

    _shimmerCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _shimmerCtrl.forward(from: 0);
        });
      }
    });
    _shimmerCtrl.forward();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<PersonalityResult>(
        future: _resultFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor));
          }

          if (!snap.hasData) {
            return const Center(child: Text('No se encontraron resultados'));
          }

          final r = snap.data!;
          final diagnosis = r.diagnosis;
          final failed = r.respuestasIncorrectas;
          final correct = r.respuestasCorrectas;
          final total = r.totalPreguntas;
          final minReq = (total * 0.6).ceil();
          final answered = r.preguntasRespondidas;
          final scoreFinal = r.scoreFinal;
          final scoreVeracidad = r.scoreVeracidad;
          final alerts = r.alertasRojas;
          final inconsistencies = r.inconsistenciasDetectadas;
          final dimScores = r.scoresPorDimension;

          final isPending = diagnosis == 'PENDIENTE';
          final isApto = diagnosis == 'APTO';

          final diagColor = isPending
              ? Colors.amber
              : isApto
                  ? Colors.greenAccent
                  : Colors.redAccent;

          final bgGradientColor = isPending
              ? Colors.amber.withOpacity(0.06)
              : isApto
                  ? Colors.green.withOpacity(0.06)
                  : Colors.red.withOpacity(0.06);

          return Stack(
            children: [
              // FONDO DE LABORATORIO (ROTACIÓN 360)
              const Positioned.fill(child: LaboratoryBackground()),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ResultHeader(
                        diagnosis: diagnosis,
                        scoreFinal: scoreFinal,
                        scoreVeracidad: scoreVeracidad,
                        diagColor: diagColor,
                        shimmerAnim: _shimmerAnim,
                        nivelVeracidad: _nivelVeracidad(scoreVeracidad),
                        alerts: alerts,
                      ),
                      const SizedBox(height: 10),
                      _buildSubtitle(isPending, isApto, r.testValido, minReq, isDark),
                      const SizedBox(height: 28),
                      ResultAlerts(
                        alertasRojas: alerts,
                        inconsistencias: inconsistencies,
                      ),
                      ResultStatCards(
                        correct: correct,
                        failed: failed,
                        answered: answered,
                        total: total,
                      ),
                      const SizedBox(height: 20),
                      _buildGlobalScoreBar(scoreFinal, diagColor, isDark),
                      const SizedBox(height: 12),
                      _buildVeracidadBar(scoreVeracidad, isDark),
                      const HistoryChart(),
                      const SizedBox(height: 28),
                      _buildTacticalPlan(dimScores, isDark),
                      const SizedBox(height: 12),
                      _buildLearningPathway(dimScores, isDark),
                      const SizedBox(height: 28),
                      _buildMotivationalMessage(diagnosis, failed, correct, answered, alerts, diagColor, isDark),
                      const SizedBox(height: 32),
                      _buildFinishButton(diagColor),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildSubtitle(bool isPending, bool isApto, bool testValido, int minReq, bool isDark) {
    return Text(
      isPending
          ? 'Necesitas al menos $minReq preguntas respondidas\npara obtener un diagnóstico válido.'
          : isApto
              ? 'Cumples con el perfil psicométrico\nrequerido para la PNP.'
              : !testValido
                  ? 'El test detectó inconsistencias en tus respuestas.\nTu sinceridad es un factor clave para el proceso.'
                  : 'Tu perfil presenta áreas críticas\nque debes trabajar para mejorar.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isDark ? Colors.white60 : Colors.black54,
        fontSize: 13,
        height: 1.6,
      ),
    );
  }

  Widget _buildGlobalScoreBar(double scoreFinal, Color diagColor, bool isDark) {
    return _scoreBar('Puntuación Global', scoreFinal / 100, '${scoreFinal.toStringAsFixed(0)}%', diagColor, isDark);
  }

  Widget _buildVeracidadBar(double scoreVeracidad, bool isDark) {
    return _scoreBar(
      'Veracidad del Test',
      scoreVeracidad / 100,
      '${scoreVeracidad.toStringAsFixed(0)}%',
      scoreVeracidad >= 80 ? Colors.greenAccent : scoreVeracidad >= 50 ? Colors.amber : Colors.redAccent,
      isDark,
    );
  }

  Widget _scoreBar(String label, double value, String valueLabel, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
              Text(valueLabel, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.07),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalMessage(String diagnosis, int failed, int correct, int answered, List<String> alerts, Color diagColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: diagColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: diagColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_rounded, color: diagColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _message(diagnosis, failed, correct, answered, alerts),
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishButton(Color diagColor) {
    return GestureDetector(
      onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: diagColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: diagColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Text(
          'VOLVER AL INICIO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  String _nivelVeracidad(double score) {
    if (score >= 80) return 'Alta';
    if (score >= 50) return 'Media';
    return 'Baja';
  }

  String _message(String diagnosis, int failed, int correct, int answered, List<String> alertas) {
    if (diagnosis == 'PENDIENTE') return 'Aún no hay suficientes datos para emitir un diagnóstico. Completa más preguntas y vuelve a intentarlo.';
    if (alertas.contains('Veracidad')) return 'El sistema detectó un patrón de respuestas que no refleja tu situación real. La honestidad es imprescindible para una evaluación válida.';
    if (alertas.contains('Corruptibilidad')) return 'Se detectaron respuestas que indican tolerancia a conductas fuera del marco ético policial. Este es un factor eliminatorio en el proceso PNP.';
    if (diagnosis == 'APTO') return '¡Excelente desempeño! Tu perfil demuestra las cualidades psicométricas necesarias para la institución. Sigue manteniéndote en este nivel.';
    if (failed >= 3) return 'Tienes varias áreas críticas que trabajar. Revisa el análisis por dimensiones y enfócate en corregir cada error con calma.';
    return 'Estás cerca del perfil ideal. Con mejoras específicas en las dimensiones con menor puntaje, alcanzarás el estándar requerido.';
  }

  Widget _buildTacticalPlan(Map<String, double> dimScores, bool isDark) {
    if (dimScores.isEmpty) return const SizedBox.shrink();

    final sorted = dimScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final weaknesses = sorted.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.gps_fixed_rounded, color: Colors.redAccent, size: 18),
            SizedBox(width: 8),
            Text(
              'PLAN DE ATAQUE TÁCTICO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...weaknesses.map((w) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              SizedBox(
                height: 30,
                width: 30,
                child: CircularProgressIndicator(
                  value: w.value / 100,
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  color: Colors.redAccent,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.key.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prioridad de refuerzo crítica. Enfócate en la Escuelita para mejorar este indicador.',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${w.value.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildLearningPathway(Map<String, double> dimScores, bool isDark) {
    final pathway = ScoringEngine.getLearningPathway(dimScores);
    if (pathway.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: AppTheme.accentColor, size: 18),
              SizedBox(width: 8),
              Text(
                'RECOMENDACIONES DE ESTUDIO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...pathway.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_right_rounded, color: AppTheme.accentColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    p,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}


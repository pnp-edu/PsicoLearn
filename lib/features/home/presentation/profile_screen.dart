import 'package:flutter/material.dart';
import 'package:psicolearn/core/theme/app_theme.dart';
import 'package:psicolearn/core/services/storage_service.dart';
import 'package:psicolearn/core/di/service_locator.dart';
import 'package:psicolearn/features/personality_test/domain/controllers/test_controller.dart';
import 'package:psicolearn/features/personality_test/domain/services/personality_test_service.dart';
import 'package:psicolearn/features/results/presentation/widgets/history_chart.dart';
import 'package:psicolearn/features/home/presentation/widgets/radar_diagnosis_chart.dart';
import 'package:psicolearn/core/utils/responsive.dart';
import 'package:psicolearn/features/spatial_test/domain/services/spatial_test_service.dart';
import '../../../core/widgets/laboratory_background.dart';


class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSettingsPressed;
  
  const ProfileScreen({
    super.key, 
    this.onSettingsPressed,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _auditFuture;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _auditFuture = _loadAudit();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }



  Future<Map<String, dynamic>> _loadAudit() async {
    final details = await TestController.getDiagnosisDetails();
    final allQ = await TestController.loadQuestionsFromAssets();
    final storage = sl<StorageService>();

    // Dimensiones maestras para el perfil PNP
    const pnpDimensions = [
      'Ética e Integridad',
      'Control de Impulsos',
      'Disciplina',
      'Liderazgo',
      'Sinceridad',
      'Resiliencia',
    ];

    final Map<String, Map<String, int>> filteredDimMap = {
      for (var dim in pnpDimensions) dim: {'correct': 0, 'total': 0, 'answered': 0}
    };

    for (final q in allQ) {
      final isCorrect = storage.getBool('correct_${q.id}') ?? false;
      final answered = storage.containsKey('answer_${q.id}');
      
      String? targetDim;
      final label = q.dimension;

      if (label.contains('Etica') || label.contains('Integridad') || label.contains('Lealtad')) {
        targetDim = 'Ética e Integridad';
      } else if (label.contains('Impulsos') || label.contains('Agresividad')) {
        targetDim = 'Control de Impulsos';
      } else if (label.contains('Disciplina') || label.contains('Reglamento')) {
        targetDim = 'Disciplina';
      } else if (label.contains('Liderazgo') || label.contains('Vocación')) {
        targetDim = 'Liderazgo';
      } else if (label.contains('Sinceridad') || label.contains('Mentira')) {
        targetDim = 'Sinceridad';
      } else if (label.contains('Resiliencia') || label.contains('Presión') || label.contains('Adaptabil')) {
        targetDim = 'Resiliencia';
      }

      if (targetDim != null) {
        filteredDimMap[targetDim]!['total'] = filteredDimMap[targetDim]!['total']! + 1;
        if (answered) filteredDimMap[targetDim]!['answered'] = filteredDimMap[targetDim]!['answered']! + 1;
        if (isCorrect) filteredDimMap[targetDim]!['correct'] = filteredDimMap[targetDim]!['correct']! + 1;
      }
    }

    final dimensionIcons = {
      'Liderazgo': Icons.emoji_events_rounded,
      'Ética e Integridad': Icons.balance_rounded,
      'Control de Impulsos': Icons.self_improvement_rounded,
      'Disciplina': Icons.checklist_rounded,
      'Sinceridad': Icons.verified_user_rounded,
      'Resiliencia': Icons.psychology_rounded,
    };
    
    final dimensionColors = {
      'Liderazgo': const Color(0xFF00BCD4),
      'Ética e Integridad': Colors.greenAccent,
      'Control de Impulsos': Colors.purpleAccent,
      'Disciplina': Colors.orangeAccent,
      'Sinceridad': Colors.amber,
      'Resiliencia': Colors.deepOrangeAccent,
    };

    final areaResults = pnpDimensions.map((dim) {
      final data = filteredDimMap[dim]!;
      final correct = data['correct']!;
      final total = data['total']!;
      final answered = data['answered']!;
      final score = answered > 0 ? correct / answered : -1.0;
      
      return {
        'label': dim,
        'icon': dimensionIcons[dim] ?? Icons.psychology_rounded,
        'color': dimensionColors[dim] ?? Colors.blueGrey,
        'correct': correct,
        'total': total,
        'score': score,
        'answered': answered,
      };
    }).toList();

    return {...details, 'areaResults': areaResults};
  }

  Color _scoreColor(double s) {
    if (s < 0) return Colors.grey;
    if (s >= 1.0) return Colors.greenAccent;
    if (s >= 0.75) return Colors.green;
    if (s >= 0.5) return Colors.orange;
    if (s >= 0.25) return Colors.deepOrange;
    return Colors.redAccent;
  }

  String _scoreLabel(double s) {
    if (s < 0) return 'SIN DATOS';
    if (s >= 1.0) return 'EXCELENTE';
    if (s >= 0.75) return 'BUENO';
    if (s >= 0.5) return 'REGULAR';
    if (s >= 0.25) return 'DÉBIL';
    return 'CRÍTICO';
  }

  Color _diagColor(String d) {
    if (d == 'APTO') return Colors.greenAccent;
    if (d == 'INAPTO') return Colors.redAccent;
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111318) : const Color(0xFFF5F7FA);
    final card = isDark ? const Color(0xFF1C2030) : Colors.white;
    final history = TestController.getHistory();
    final spatialBest = sl<SpatialTestService>().getBestScore();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'AUDITORÍA DE PERSONALIDAD',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: Responsive.titleFontSize(context, mobile: 14),
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.grey, size: 20),
            onPressed: widget.onSettingsPressed,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.accentColor),
            onPressed: () async {
              await sl<PersonalityTestService>().syncDiagnosis();
              setState(() => _auditFuture = _loadAudit());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Fondo de Laboratorio
          const Positioned.fill(child: LaboratoryBackground()),
          // Efecto de escaneo táctico

          AnimatedBuilder(
            animation: _scanController,
            builder: (context, child) {
              return Positioned(
                top: _scanController.value * MediaQuery.of(context).size.height,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.accentColor.withOpacity(0.0),
                        AppTheme.accentColor.withOpacity(0.05),
                        AppTheme.accentColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: _auditFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
              }
              if (!snap.hasData) return const Center(child: Text('Error al cargar análisis'));

              final d = snap.data!;
              final diagnosis = d['diagnosis'] as String;
              final failed = d['failed_count'] as int;
              final correct = d['correct_count'] as int;
              final answered = d['total_answered'] as int;
              final total = d['total_questions'] as int;
              final minReq = d['min_required'] as int;
              final progressUnlock = d['progress_to_unlock'] as double;
              final pct = d['percentage'] as String;
              final areas = d['areaResults'] as List<Map<String, dynamic>>;
              final isPending = diagnosis == 'PENDIENTE';
              final diagColor = _diagColor(diagnosis);
              final overallScore = answered > 0 ? correct / answered : 0.0;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [diagColor.withOpacity(0.2), diagColor.withOpacity(0.05)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: diagColor.withOpacity(0.35), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: diagColor.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: diagColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: diagColor.withOpacity(0.5)),
                              ),
                              child: Text(diagnosis,
                                style: TextStyle(color: diagColor, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2),
                              ),
                            ),
                            const Spacer(),
                            Text('$pct%',
                              style: TextStyle(color: diagColor, fontSize: 28, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (isPending) ...[
                          Text(
                            'Diagnóstico en progreso',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Necesitas responder al menos $minReq preguntas para obtener tu diagnóstico. Llevas $answered.',
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progressUnlock,
                              minHeight: 10,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('$answered / $minReq preguntas mínimas',
                            style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w700),
                          ),
                        ] else ...[
                          Text(
                            diagnosis == 'APTO' ? 'Perfil Validado PNP' : 'Perfil requiere mejora',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black87),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            diagnosis == 'APTO'
                              ? 'Tu personalidad cumple los estándares psicométricos requeridos.'
                              : 'Tienes $failed áreas que corregir. La constancia es clave para lograrlo.',
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),

                RadarDiagnosisChart(areaResults: areas),
                const SizedBox(height: 20),

                // ── STATS ROW ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(children: [
                    _stat('✓ Correctas', correct.toString(), Colors.greenAccent, card),
                    const SizedBox(width: 8),
                    _stat('✗ Falladas', failed.toString(), Colors.redAccent, card),
                    const SizedBox(width: 8),
                    _stat('○ Pendientes', (total - answered).toString(), Colors.amber, card),
                  ]),
                ),
                const SizedBox(height: 24),

                // ── EVOLUCIÓN SUMMARY ROW ─────────────────────────────────
                _buildEvolucionSummary(history, spatialBest, isDark, card),

                const HistoryChart(),
                const SizedBox(height: 24),

                // ── HISTORIAL DE SIMULACROS ────────────────────────────────
                if (history.isNotEmpty) ...[
                  _sectionTitle('HISTORIAL DE SIMULACROS', isDark),
                  const SizedBox(height: 12),
                  ...history.reversed.map((e) => _buildHistoryItem(e, isDark, card)),
                  const SizedBox(height: 24),
                ],

                // ── RECOMENDACIÓN ─────────────────────────────────────────
                if (!isPending) ...[
                  _sectionTitle('RECOMENDACIÓN', isDark),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _scoreColor(overallScore).withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.tips_and_updates_rounded, color: _scoreColor(overallScore), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _recommendation(failed, overallScore),
                            style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/portada-pnp.png',
                      width: 500,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    ],
  ),
);
}

  Widget _sectionTitle(String t, bool isDark) => Row(children: [
    Container(width: 3, height: 14, color: AppTheme.accentColor, margin: const EdgeInsets.only(right: 8)),
    Text(t, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5,
        color: isDark ? Colors.white60 : Colors.black45)),
  ]);

  Widget _stat(String label, String value, Color color, Color card) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(
            fontSize: Responsive.titleFontSize(context, mobile: 18), 
            fontWeight: FontWeight.w900, 
            color: color
          )),
          const SizedBox(height: 2),
          Text(label, 
            style: TextStyle(fontSize: Responsive.isSmallMobile(context) ? 8 : 10, fontWeight: FontWeight.w600), 
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );

  Widget _areaCard(Map<String, dynamic> a, Color card, bool isDark) {
    final color = a['color'] as Color;
    final score = a['score'] as double;
    final correct = a['correct'] as int;
    final total = a['total'] as int;
    final answered = a['answered'] as int;
    final sc = _scoreColor(score);
    final sl = _scoreLabel(score);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(a['icon'] as IconData, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(a['label'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(sl, style: TextStyle(color: sc, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.8)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: answered == 0 ? 0 : score.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.07),
                valueColor: AlwaysStoppedAnimation<Color>(sc),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(answered == 0 ? '—' : '$correct/$total',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: sc)),
        ]),
      ]),
    );
  }


  String _recommendation(int failed, double score) {
    if (failed == 0) return 'Tu perfil psicológico cumple los estándares PNP. Mantén esta consistencia.';
    if (score >= 0.7) return 'Estás cerca del perfil ideal. Corrige las áreas marcadas para consolidar tu diagnóstico.';
    if (score >= 0.4) return 'Tienes áreas importantes que trabajar. Enfócate en el autocontrol y la disciplina.';
    return 'Tu perfil requiere trabajo profundo. Analiza cada área crítica con calma. La constancia es la clave.';
  }

  Widget _buildEvolucionSummary(List<Map<String, dynamic>> history, int spatialBest, bool isDark, Color cardColor) {
    if (history.isEmpty) return const SizedBox.shrink();
    
    final lastScore = (history.last['score'] as num).toDouble();
    final avgScore = history.map((e) => (e['score'] as num).toDouble()).reduce((a, b) => a + b) / history.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          _summaryItem('Último Psico', '${lastScore.toStringAsFixed(0)}%', AppTheme.accentColor, isDark, cardColor),
          const SizedBox(width: 8),
          _summaryItem('Promedio', '${avgScore.toStringAsFixed(0)}%', Colors.purpleAccent, isDark, cardColor),
          const SizedBox(width: 8),
          _summaryItem('Récord Espacial', '$spatialBest%', Colors.tealAccent, isDark, cardColor),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color, bool isDark, Color cardColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label, 
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)
            ),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> entry, bool isDark, Color cardColor) {
    final date = DateTime.parse(entry['date']);
    final score = (entry['score'] as num).toDouble();
    final dateStr = '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const Text('Simulacro completado', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: score >= 75 ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

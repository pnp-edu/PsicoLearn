import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';

class RadarDiagnosisChart extends StatelessWidget {
  final List<Map<String, dynamic>> areaResults;

  const RadarDiagnosisChart({super.key, required this.areaResults});

  // Dimensiones maestras para el perfil PNP
  static const List<String> pnpDimensions = [
    'Ética e Integridad',
    'Control de Impulsos',
    'Disciplina',
    'Liderazgo',
    'Sinceridad',
    'Resiliencia',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filtrar y agrupar resultados para el perfil PNP
    final Map<String, double> filteredMap = {
      for (var dim in pnpDimensions) dim: 0.0
    };

    for (var res in areaResults) {
      final label = res['label'] as String;
      final score = res['score'] as double;
      
      if (label.contains('Etica') || label.contains('Integridad') || label.contains('Lealtad')) {
        filteredMap['Ética e Integridad'] = score;
      } else if (label.contains('Impulsos') || label.contains('Agresividad')) {
        filteredMap['Control de Impulsos'] = score;
      } else if (label.contains('Disciplina') || label.contains('Reglamento')) {
        filteredMap['Disciplina'] = score;
      } else if (label.contains('Liderazgo') || label.contains('Vocación')) {
        filteredMap['Liderazgo'] = score;
      } else if (label.contains('Sinceridad') || label.contains('Mentira')) {
        filteredMap['Sinceridad'] = score;
      } else if (label.contains('Resiliencia') || label.contains('Presión') || label.contains('Adaptabil')) {
        filteredMap['Resiliencia'] = score;
      }
    }

    final List<Map<String, dynamic>> finalData = pnpDimensions.map((dim) {
      return {'label': dim, 'score': filteredMap[dim]};
    }).toList();

    if (finalData.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 360,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EQUILIBRIO TÁCTICO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
              _buildLegend(isDark),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.circle,
                radarBorderData: const BorderSide(color: Colors.transparent),
                gridBorderData: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  width: 1,
                ),
                tickBorderData: const BorderSide(color: Colors.transparent),
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                titleTextStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                getTitle: (index, angle) {
                  final label = finalData[index]['label'] as String;
                  final Map<String, String> abbreviations = {
                    'Ética e Integridad': 'ÉTICA',
                    'Control de Impulsos': 'CONTROL',
                    'Disciplina': 'DISCIPL.',
                    'Liderazgo': 'LIDER.',
                    'Sinceridad': 'SINCER.',
                    'Resiliencia': 'RESIL.',
                  };
                  return RadarChartTitle(
                    text: abbreviations[label] ?? label,
                    angle: angle,
                  );
                },
                dataSets: [
                  // DATASET 1: Perfil Ideal (Sombreado suave)
                  RadarDataSet(
                    fillColor: Colors.purpleAccent.withOpacity(0.08),
                    borderColor: Colors.purpleAccent.withOpacity(0.3),
                    borderWidth: 1,
                    entryRadius: 0,
                    dataEntries: List.generate(6, (i) => const RadarEntry(value: 90)),
                  ),
                  // DATASET 2: Usuario (Brillante y Enfocado)
                  RadarDataSet(
                    fillColor: AppTheme.accentColor.withOpacity(0.25),
                    borderColor: AppTheme.accentColor,
                    borderWidth: 2.5,
                    entryRadius: 4.5,
                    dataEntries: finalData.map((e) {
                      final score = (e['score'] as double).clamp(0.0, 1.0);
                      // Ajustamos escala para que no se pegue a los bordes
                      return RadarEntry(value: (score * 85) + 5);
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Row(
      children: [
        _legendItem('TU PERFIL', AppTheme.accentColor),
        const SizedBox(width: 12),
        _legendItem('IDEAL', Colors.purpleAccent.withOpacity(0.5)),
      ],
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }
}

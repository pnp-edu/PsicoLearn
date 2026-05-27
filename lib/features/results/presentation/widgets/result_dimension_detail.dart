import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:psicolearn/core/theme/app_theme.dart';

class ResultDimensionDetail extends StatelessWidget {
  final Map<String, double> dimScores;
  final Color diagColor;

  const ResultDimensionDetail({
    super.key,
    required this.dimScores,
    required this.diagColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (dimScores.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        _sectionTitle('Análisis Psicométrico 360°', isDark),
        const SizedBox(height: 20),
        _buildRadarChart(dimScores, diagColor, isDark),
        const SizedBox(height: 32),
        _sectionTitle('Detalle por Dimensiones', isDark),
        const SizedBox(height: 14),
        ...dimScores.entries.map((e) {
          final color = _colorForDimension(e.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildScoreBar(
              e.key,
              e.value / 100,
              '${e.value.toStringAsFixed(0)}%',
              color,
              isDark,
            ),
          );
        }),
      ],
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 13,
        letterSpacing: 1.0,
        color: isDark ? Colors.white54 : Colors.black45,
      ),
    );
  }

  Widget _buildScoreBar(
      String label, double value, String valueLabel, Color color, bool isDark) {
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
              Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  )),
              Text(valueLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: color,
                  )),
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
                backgroundColor: isDark
                    ? Colors.white10
                    : Colors.black.withOpacity(0.07),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForDimension(String dimension) {
    final colors = {
      'Liderazgo': const Color(0xFF00BCD4),
      'Etica': Colors.greenAccent,
      'Estabilidad Emocional': Colors.purpleAccent,
      'Disciplina': Colors.orangeAccent,
      'Sociabilidad': const Color(0xFF64B5F6),
      'Sinceridad': Colors.amber,
    };
    return colors[dimension] ?? AppTheme.accentColor;
  }

  Widget _buildRadarChart(
      Map<String, double> dimScores, Color diagColor, bool isDark) {
    final List<String> dimensions = dimScores.keys.toList();
    if (dimensions.length < 3) return const SizedBox.shrink();

    final gridColor = isDark ? Colors.white10 : Colors.black12;
    final tickColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D1F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: diagColor.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: diagColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          radarTouchData: RadarTouchData(enabled: true),
          dataSets: [
            RadarDataSet(
              fillColor: diagColor.withOpacity(0.25),
              borderColor: diagColor,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: dimensions
                  .map((d) => RadarEntry(value: dimScores[d] ?? 0))
                  .toList(),
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.transparent),
          gridBorderData: BorderSide(color: gridColor, width: 1),
          tickBorderData: BorderSide(color: tickColor, width: 1),
          ticksTextStyle: TextStyle(color: tickColor, fontSize: 8),
          tickCount: 4,
          getTitle: (index, angle) {
            final label = dimensions[index % dimensions.length];
            final shortLabel =
                label.length > 10 ? '${label.substring(0, 8)}..' : label;
            return RadarChartTitle(
              text: shortLabel,
              angle: angle,
            );
          },
          titleTextStyle: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

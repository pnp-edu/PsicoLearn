import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../personality_test/domain/controllers/test_controller.dart';

class HistoryChart extends StatelessWidget {
  const HistoryChart({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = TestController.getHistory();
    
    if (history.isEmpty) return const SizedBox.shrink();

    // Tomar solo los últimos 7 registros
    final recentHistory = history.length > 10 ? history.sublist(history.length - 10) : history;

    return Container(
      height: 240,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 24, 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LÍNEA DE RENDIMIENTO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
              Icon(Icons.trending_up_rounded, color: AppTheme.accentColor, size: 16),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'S${value.toInt() + 1}',
                            style: TextStyle(
                              color: isDark ? Colors.white24 : Colors.black26,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            color: isDark ? Colors.white24 : Colors.black26,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(recentHistory.length, (i) {
                      final score = (recentHistory[i]['score'] as num).toDouble();
                      return FlSpot(i.toDouble(), score);
                    }),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.accentColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 5,
                        color: AppTheme.accentColor,
                        strokeWidth: 3,
                        strokeColor: isDark ? const Color(0xFF161B22) : Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentColor.withOpacity(0.3),
                          AppTheme.accentColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 105,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

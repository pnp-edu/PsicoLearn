import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../personality_test/domain/controllers/test_controller.dart';
import '../../spatial_test/domain/services/spatial_test_service.dart';
import '../../../core/widgets/laboratory_background.dart';
import '../../../core/di/service_locator.dart';

class ProgressScreen extends StatelessWidget {
  final VoidCallback onBack;
  const ProgressScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    final history = TestController.getHistory();

    if (history.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: textColor),
            onPressed: onBack,
          ),
          title: Text('MI EVOLUCIÓN', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        body: LaboratoryBackground(child: _buildEmptyState(isDark)),
      );
    }

    final spatialBest = sl<SpatialTestService>().getBestScore();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textColor),
          onPressed: onBack,
        ),
        title: Text(
          'MI EVOLUCIÓN',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: LaboratoryBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummary(history, spatialBest, isDark),
              const SizedBox(height: 32),
              Text(
                'CURVA DE RENDIMIENTO',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              _buildChart(history, isDark),
              const SizedBox(height: 32),
              Text(
                'HISTORIAL RECIENTE',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              ...history.reversed.map((e) => _buildHistoryItem(e, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text(
            'Aún no hay datos de progreso.\nCompleta tu primer test para ver tu evolución.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<Map<String, dynamic>> history, int spatialBest, bool isDark) {
    final lastScore = history.last['score'] as double;
    final avgScore = history.map((e) => e['score'] as double).reduce((a, b) => a + b) / history.length;

    return Row(
      children: [
        _summaryItem('Último Psico', '${lastScore.toStringAsFixed(0)}%', AppTheme.accentColor, isDark),
        const SizedBox(width: 8),
        _summaryItem('Promedio', '${avgScore.toStringAsFixed(0)}%', Colors.purpleAccent, isDark),
        const SizedBox(width: 8),
        _summaryItem('Récord Espacial', '$spatialBest%', Colors.tealAccent, isDark),
      ],
    );
  }

  Widget _summaryItem(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> history, bool isDark) {
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: history.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), (e.value['score'] as double));
              }).toList(),
              isCurved: true,
              color: AppTheme.accentColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.accentColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> entry, bool isDark) {
    final date = DateTime.parse(entry['date']);
    final score = entry['score'] as double;
    final dateStr = '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              color: score >= 75 ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

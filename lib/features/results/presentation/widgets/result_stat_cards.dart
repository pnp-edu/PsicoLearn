import 'package:flutter/material.dart';
import 'package:psicolearn/core/theme/app_theme.dart';
import 'package:psicolearn/core/utils/responsive.dart';

class ResultStatCards extends StatelessWidget {
  final int correct;
  final int failed;
  final int answered;
  final int total;

  const ResultStatCards({
    super.key,
    required this.correct,
    required this.failed,
    required this.answered,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        _statCard(context, 'Correctas', correct.toString(), Colors.greenAccent, isDark),
        const SizedBox(width: 10),
        _statCard(context, 'Errores', failed.toString(), Colors.redAccent, isDark),
        const SizedBox(width: 10),
        _statCard(context, 'Total', '$answered/$total', AppTheme.accentColor, isDark),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: Responsive.titleFontSize(context, mobile: 18), 
                    fontWeight: FontWeight.w900, 
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: Responsive.isSmallMobile(context) ? 8 : 10, 
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

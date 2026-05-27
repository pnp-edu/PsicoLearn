import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SpatialHeader extends StatelessWidget {
  final String questionType;
  final int currentIndex;
  final int totalQuestions;
  final VoidCallback onBackPressed;

  const SpatialHeader({
    super.key,
    required this.questionType,
    required this.currentIndex,
    required this.totalQuestions,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isSmall = MediaQuery.of(context).size.width < 380;
    final scale = (MediaQuery.of(context).size.width / 375.0).clamp(0.8, 1.0);

    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 16 * scale, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón Atrás Premium
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBackPressed,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 20 * scale,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          
          if (!isSmall) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MÓDULO TÁCTICO',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10 * scale,
                    letterSpacing: 2.0,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                Text(
                  questionType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accentColor,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],

          const Spacer(),
          
          // Contador de Preguntas
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${currentIndex + 1}',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16 * scale,
                  height: 1.0,
                ),
              ),
              Text(
                'DE $totalQuestions',
                style: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontWeight: FontWeight.w900,
                  fontSize: 8 * scale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

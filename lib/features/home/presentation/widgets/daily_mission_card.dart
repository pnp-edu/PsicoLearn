import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DailyMissionCard extends StatelessWidget {
  final bool todayCompleted;
  final int questionsAnswered;
  final int totalQuestions;
  final VoidCallback onTap;

  const DailyMissionCard({
    super.key,
    required this.todayCompleted,
    required this.questionsAnswered,
    required this.totalQuestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return GestureDetector(
      onTap: todayCompleted ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 14 : 16,
          vertical: isCompact ? 12 : 14,
        ),
        decoration: BoxDecoration(
          gradient: todayCompleted
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: todayCompleted ? cardBg : null,
          borderRadius: BorderRadius.circular(20),
          border: todayCompleted
              ? Border.all(color: AppTheme.accentColor.withOpacity(0.2))
              : null,
          boxShadow: [
            if (!todayCompleted)
              BoxShadow(
                color: AppTheme.accentColor.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 9 : 11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                todayCompleted
                    ? Icons.check_circle_rounded
                    : Icons.bolt_rounded,
                color: todayCompleted ? Colors.greenAccent : Colors.white,
                size: isCompact ? 20 : 22,
              ),
            ),
            SizedBox(width: isCompact ? 12 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MISIÓN DIARIA',
                    style: TextStyle(
                      color: todayCompleted
                          ? AppTheme.accentColor
                          : Colors.white.withOpacity(0.8),
                      fontSize: isCompact ? 9 : 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    todayCompleted ? '¡Misión Cumplida!' : 'Entrenamiento de Hoy',
                    style: TextStyle(
                      color: todayCompleted ? (isDark ? Colors.white : Colors.black87) : Colors.white,
                      fontSize: isCompact ? 14 : 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (!todayCompleted && totalQuestions > 0) ...[
                    SizedBox(height: isCompact ? 4 : 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: questionsAnswered / totalQuestions,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 3,
                      ),
                    ),
                    SizedBox(height: isCompact ? 3 : 4),
                    Text(
                      '$questionsAnswered / $totalQuestions preguntas',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: isCompact ? 9 : 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!todayCompleted)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: isCompact ? 14 : 16,
              ),
          ],
        ),
      ),
    );
  }
}

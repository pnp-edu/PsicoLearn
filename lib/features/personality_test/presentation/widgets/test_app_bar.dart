import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TestAppBar extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final double progress;
  final bool isCorrectingErrors;
  final VoidCallback onBackPressed;

  const TestAppBar({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.progress,
    required this.isCorrectingErrors,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backColor = isDark ? Colors.white : Colors.black87;

    return SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: backColor),
                onPressed: onBackPressed,
              ),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.accentColor,
                      ),
                      minHeight: 4,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${currentIndex + 1}/$totalQuestions',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (isCorrectingErrors)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
              color: Colors.orange.withOpacity(0.1),
              child: const Text(
                'MODO CORRECCIÓN DE ERRORES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

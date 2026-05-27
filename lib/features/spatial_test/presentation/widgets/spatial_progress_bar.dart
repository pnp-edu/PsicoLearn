import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SpatialProgressBar extends StatelessWidget {
  final double progress;

  const SpatialProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
      ),
      child: Stack(
        children: [
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentColor.withOpacity(0.5),
                    AppTheme.accentColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

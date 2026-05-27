import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:psicolearn/core/theme/app_theme.dart';

class TimerOverlay extends StatelessWidget {
  final int remainingSeconds;
  final String phase;
  final Animation<double> pulseAnimation;

  const TimerOverlay({
    super.key,
    required this.remainingSeconds,
    required this.phase,
    required this.pulseAnimation,
  });


  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnd = phase == 'end';
    final isMid = phase == 'mid';
    final accentColor = isEnd
        ? Colors.redAccent
        : (isMid ? Colors.amberAccent : AppTheme.accentColor);
    final label = isEnd ? '¡FINAL!' : (isMid ? 'MITAD' : 'TIEMPO');
    final timeText = _formatTime(remainingSeconds);

    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161B22).withOpacity(0.9)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withOpacity(
                      isEnd ? pulseAnimation.value : 0.5,
                    ),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(
                        isEnd ? 0.4 * pulseAnimation.value : 0.2,
                      ),
                      blurRadius: isEnd ? 15 * pulseAnimation.value : 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEnd ? Icons.timer_off_rounded : Icons.timer_rounded,
                          color: accentColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 8,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              timeText,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

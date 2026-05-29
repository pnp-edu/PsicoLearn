import 'package:flutter/material.dart';
import 'package:psicolearn/core/theme/app_theme.dart';
import 'package:psicolearn/core/utils/responsive.dart';

class GlowingQuestion extends StatefulWidget {
  final String text;
  final Color? color;
  const GlowingQuestion({super.key, required this.text, this.color});

  @override
  State<GlowingQuestion> createState() => _GlowingQuestionState();
}

class _GlowingQuestionState extends State<GlowingQuestion>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 8.0,
      end: 28.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (widget.color ?? AppTheme.accentColor).withOpacity(
                  isDark ? 0.06 : 0.04,
                ),
                blurRadius: _glow.value * 3,
                spreadRadius: _glow.value * 0.4,
              ),
            ],
          ),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: Responsive.titleFontSize(context, mobile: 22, desktop: 32),
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -0.3,
              shadows: [
                Shadow(
                  color: (widget.color ?? AppTheme.accentColor).withOpacity(
                    isDark ? 0.4 : 0.1,
                  ),
                  blurRadius: _glow.value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

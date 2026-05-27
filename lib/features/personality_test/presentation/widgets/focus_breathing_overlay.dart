import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:psicolearn/core/theme/app_theme.dart';

class FocusBreathingOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const FocusBreathingOverlay({super.key, required this.onComplete});

  @override
  State<FocusBreathingOverlay> createState() => _FocusBreathingOverlayState();
}

class _FocusBreathingOverlayState extends State<FocusBreathingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  String _message = 'INHALA';
  int _secondsLeft = 12;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _message = 'EXHALA');
          _controller.reverse();
          HapticFeedback.mediumImpact();
        } else if (status == AnimationStatus.dismissed) {
          setState(() => _message = 'INHALA');
          _controller.forward();
          HapticFeedback.mediumImpact();
        }
      });

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
    HapticFeedback.mediumImpact();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        widget.onComplete();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'PREPARACIÓN MENTAL',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 60),
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Container(
                  width: 120 * _scaleAnimation.value,
                  height: 120 * _scaleAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accentColor.withOpacity(0.4),
                        AppTheme.accentColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 60),
            Text(
              'EL TEST COMIENZA EN $_secondsLeft',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

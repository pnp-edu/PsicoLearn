import 'package:flutter/material.dart';

class QuestionTransition extends StatelessWidget {
  final int questionIndex;
  final Widget child;

  const QuestionTransition({
    super.key,
    required this.questionIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Slide up and fade in
        final inAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.2), // Start from bottom
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        // Slide up and fade out (for the outgoing widget)
        final outAnimation = Tween<Offset>(
          begin: const Offset(0.0, -0.2), // Exit towards top
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInCubic,
        ));

        if (child.key == ValueKey<int>(questionIndex)) {
          // This is the incoming widget
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: inAnimation,
              child: child,
            ),
          );
        } else {
          // This is the outgoing widget
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: outAnimation,
              child: child,
            ),
          );
        }
      },
      child: child,
    );
  }
}

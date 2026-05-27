import 'package:flutter/material.dart';
import 'package:psicolearn/core/theme/app_theme.dart';

class GhostPulseBorder extends StatelessWidget {
  final Animation<double> animation;

  const GhostPulseBorder({
    super.key,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.transparent,
                    AppTheme.accentColor.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  stops: [
                    (animation.value - 0.2).clamp(0.0, 1.0),
                    animation.value,
                    (animation.value + 0.2).clamp(0.0, 1.0),
                  ],
                ).createShader(rect);
              },
              blendMode: BlendMode.srcATop,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2.5,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';

class DashboardHeader extends StatelessWidget {
  final String diagnosis;
  final Animation<double> pulseAnimation;

  const DashboardHeader({
    super.key,
    required this.diagnosis,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 520;
        final isVeryCompact = width < 380;
        final animationSize = isVeryCompact ? 70.0 : (isCompact ? 85.0 : 110.0);
        final topCircleSize = isVeryCompact ? 80.0 : (isCompact ? 120.0 : 160.0);
        final horizontalPadding = Responsive.horizontalPadding(context);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            isVeryCompact ? 2 : (isCompact ? 4 : 8),
            horizontalPadding,
            isVeryCompact ? 2 : 2,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -topCircleSize * 0.15,
                child: Container(
                  width: topCircleSize,
                  height: topCircleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.12),
                        blurRadius: 80,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                ),
              ),
              isCompact
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/animations/meditating_brain.json',
                          width: animationSize,
                          height: animationSize,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: isVeryCompact ? 2 : 4),
                        _buildDiagnosisText(isVeryCompact),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/animations/meditating_brain.json',
                          width: animationSize,
                          height: animationSize,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: isCompact ? 15 : 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDiagnosisText(false),
                            ],
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiagnosisText(bool isVeryCompact) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final baseColor = diagnosis == 'APTO'
            ? Colors.greenAccent
            : (diagnosis == 'PENDIENTE' || diagnosis == '...'
                ? Colors.amberAccent
                : Colors.redAccent);

        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              baseColor.withOpacity(0.7),
              baseColor,
              Colors.white,
              baseColor,
              baseColor.withOpacity(0.7),
            ],
            stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
            begin: Alignment(pulseAnimation.value - 1, 0),
            end: Alignment(pulseAnimation.value + 1, 0),
          ).createShader(bounds),
          child: Text(
            diagnosis,
            style: TextStyle(
              color: Colors.white,
              fontSize: isVeryCompact ? 24 : 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_theme.dart';

class ResultHeader extends StatelessWidget {
  final String diagnosis;
  final double scoreFinal;
  final double scoreVeracidad;
  final Color diagColor;
  final Animation<double> shimmerAnim;
  final String nivelVeracidad;
  final List<String> alerts;

  const ResultHeader({
    super.key,
    required this.diagnosis,
    required this.scoreFinal,
    required this.scoreVeracidad,
    required this.diagColor,
    required this.shimmerAnim,
    required this.nivelVeracidad,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accentColor;
    final isPending = diagnosis == 'PENDIENTE';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: diagColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: diagColor.withOpacity(0.4)),
          ),
          child: Text(
            isPending ? 'DIAGNÓSTICO INCOMPLETO' : 'RESULTADO FINAL',
            style: TextStyle(
              color: diagColor,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 160,
          height: 160,
          child: Lottie.asset(
            'assets/animations/meditating_brain.json',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.psychology_rounded,
              color: diagColor,
              size: 90,
            ),
          ),
        ),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: shimmerAnim,
          builder: (ctx, _) {
            return ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  diagColor.withOpacity(0.6),
                  diagColor,
                  Colors.white,
                  diagColor,
                  diagColor.withOpacity(0.6),
                ],
                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                begin: Alignment(shimmerAnim.value - 1, 0),
                end: Alignment(shimmerAnim.value + 1, 0),
              ).createShader(bounds),
              child: Text(
                diagnosis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: diagnosis.length > 8 
                    ? 32.0 * (MediaQuery.of(context).size.width / 375.0).clamp(0.8, 1.0)
                    : 48.0 * (MediaQuery.of(context).size.width / 375.0).clamp(0.8, 1.0),
                  fontWeight: FontWeight.w900,
                  letterSpacing: diagnosis.length > 8 ? 2 : 4,
                ),
              ),
            );
          },
        ),
        if (!isPending) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${scoreFinal.toStringAsFixed(0)}/100',
                style: TextStyle(
                  color: diagColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (scoreVeracidad >= 80
                          ? Colors.greenAccent
                          : scoreVeracidad >= 50
                              ? Colors.amber
                              : Colors.redAccent)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Veracidad: $nivelVeracidad',
                  style: TextStyle(
                    color: scoreVeracidad >= 80
                        ? Colors.greenAccent
                        : scoreVeracidad >= 50
                            ? Colors.amber
                            : Colors.redAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (diagnosis == 'INAPTO' && alerts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: alerts.take(2).map((a) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Text(
                  a.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ],
    );
  }
}

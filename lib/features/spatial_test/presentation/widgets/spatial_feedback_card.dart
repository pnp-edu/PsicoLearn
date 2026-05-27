import 'package:flutter/material.dart';

class SpatialFeedbackCard extends StatelessWidget {
  final bool isCorrect;
  final String correctOption;
  final String explanation;
  final bool isLast;
  final VoidCallback onContinue;

  const SpatialFeedbackCard({
    super.key,
    required this.isCorrect,
    required this.correctOption,
    required this.explanation,
    required this.isLast,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isCorrect ? Colors.greenAccent : Colors.redAccent;

    final scale = (MediaQuery.of(context).size.width / 375.0).clamp(0.8, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? accent.withOpacity(0.08) : accent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(12 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.auto_awesome : Icons.info_outline_rounded,
                  color: accent,
                  size: 18 * scale,
                ),
              ),
              SizedBox(width: 10 * scale),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? '¡EXCELENTE!' : 'PATRÓN DETECTADO',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 10 * scale,
                    ),
                  ),
                  if (!isCorrect)
                    Text(
                      'La respuesta correcta era: $correctOption',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 11 * scale,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(10 * scale),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              explanation,
              style: TextStyle(
                fontSize: 12 * scale,
                height: 1.4,
                color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(vertical: 12 * scale),
              ),
              onPressed: onContinue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? 'FINALIZAR EVALUACIÓN' : 'CONTINUAR AL SIGUIENTE ITEM',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 13 * scale,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

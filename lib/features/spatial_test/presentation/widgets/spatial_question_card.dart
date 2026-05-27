import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/spatial_question.dart';

class SpatialQuestionCard extends StatelessWidget {
  final SpatialQuestion question;
  final int index;

  const SpatialQuestionCard({
    super.key,
    required this.question,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scale = (MediaQuery.of(context).size.width / 375.0).clamp(0.8, 1.0);
    final isSmall = MediaQuery.of(context).size.width < 360;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2128) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.black.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
            blurRadius: 40,
            spreadRadius: -5,
            offset: const Offset(0, 20),
          ),
          if (isDark)
            BoxShadow(
              color: AppTheme.accentColor.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: -10,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.titulo,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14 * scale,
                height: 1.1,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              question.instruccion,
              style: TextStyle(
                fontSize: 11 * scale,
                height: 1.3,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: isSmall ? 140 : 180, // Altura fija garantizada para el SVG en horizontal
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset(
                question.secuenciaAsset,
                fit: BoxFit.contain,
                placeholderBuilder: (ctx) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

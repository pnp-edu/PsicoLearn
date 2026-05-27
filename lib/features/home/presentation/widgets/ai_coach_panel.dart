import 'package:flutter/material.dart';
import 'package:psicolearn/core/theme/app_theme.dart';

class AICoachPanel extends StatelessWidget {
  final String weakestDimension;
  final double score;

  const AICoachPanel({
    super.key,
    required this.weakestDimension,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coachTip = _getCoachTip(weakestDimension);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'PERSONAL AI COACH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Basado en tu desempeño en $weakestDimension:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            coachTip,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressBar(score, isDark),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double value, bool isDark) {
    final color = value < 50 ? Colors.redAccent : (value < 75 ? Colors.orangeAccent : Colors.greenAccent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Estado de la Dimensión',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
            ),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 4,
            backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  String _getCoachTip(String dim) {
    final tips = {
      'Etica e Integridad': 'Recuerda que la honestidad no tiene matices. En el servicio, lo correcto es absoluto, incluso si nadie te observa.',
      'Sinceridad': 'He detectado que intentas proyectar una imagen perfecta. En la PNP se valora la autenticidad sobre la perfección fingida.',
      'Estabilidad Emocional': 'Ante la presión, respira. No respondas desde la impulsividad; busca siempre la neutralidad en tus respuestas.',
      'Disciplina': 'Las normas son la columna vertebral de la institución. Entrena tu mente para ver el reglamento como una guía, no como un obstáculo.',
      'Liderazgo': 'Un líder no solo manda, organiza y asume la responsabilidad del equipo. Enfócate en soluciones colectivas.',
      'Empatía': 'El servicio policial es servicio humano. Intenta conectar con la vulnerabilidad de los ciudadanos en cada caso.',
      'Resiliencia': 'El fracaso es parte del adiestramiento. Cada error en el app es una oportunidad de no fallar en el examen real.',
    };
    return tips[dim] ?? 'Sigue practicando diariamente para consolidar tu perfil psicométrico ideal.';
  }
}

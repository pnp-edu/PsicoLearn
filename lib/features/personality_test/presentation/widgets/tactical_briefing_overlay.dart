import 'package:flutter/material.dart';
import 'package:psicolearn/core/theme/app_theme.dart';

class TacticalBriefingOverlay extends StatelessWidget {
  final String dimension;
  final VoidCallback onStart;

  const TacticalBriefingOverlay({
    super.key,
    required this.dimension,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final briefing = _getBriefing(dimension);

    return Container(
      color: Colors.black.withOpacity(0.98),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: AppTheme.accentColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'BRIEFING TÁCTICO',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'REFORZANDO: ${dimension.toUpperCase()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(isDark, briefing),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  'ENTENDIDO, EMPEZAR TEST',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getBriefing(String dim) {
    final briefings = {
      'Etica e Integridad': 'La ética policial no es negociable. Ante dilemas morales, la respuesta correcta siempre prioriza el reglamento y la transparencia sobre la conveniencia personal o grupal.',
      'Sinceridad': 'El polígrafo y los tests psicométricos detectan la "Deseabilidad Social". No intentes ser perfecto; intenta ser honesto. La imperfección honesta es mejor que la perfección fingida.',
      'Control de Impulsos': 'Un policía bajo presión debe ser un pilar de calma. En este test, evita las respuestas extremas o violentas. Busca siempre la mediación y el uso proporcional de la fuerza.',
      'Disciplina': 'La jerarquía es la base de la PNP. Respeta siempre la cadena de mando y las normas establecidas, incluso si no estás de acuerdo personalmente.',
      'Relaciones Interpersonales': 'El trabajo policial es en equipo. Valora la cooperación y la empatía. Un perfil solitario o conflictivo es un riesgo operativo.',
    };
    return briefings[dim] ?? 'Analiza cada pregunta con calma. El éxito en la PNP depende de tu equilibrio mental y tu capacidad de juicio ético bajo presión.';
  }
}

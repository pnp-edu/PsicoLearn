/// Resultado psicométrico avanzado del test PNP
class PersonalityResult {
  // ── Score Global ──────────────────────────────────────────────────────────
  /// Score final de 0 a 100, calculado con ponderación por peso crítico
  final double scoreFinal;

  /// Diagnóstico: APTO, INAPTO, o PENDIENTE
  final String diagnosis;

  // ── Scores por Dimensión ─────────────────────────────────────────────────
  /// Mapa de dimensión → score 0-100 (ej: {'Liderazgo': 85.0, 'Etica': 60.0})
  final Map<String, double> scoresPorDimension;

  // ── Indicadores de Calidad del Test ──────────────────────────────────────
  /// Porcentaje de veracidad (0-100): penalizado por fallos en escala mentira
  final double scoreVeracidad;

  /// true si el test es considerado válido (sin manipulación evidente)
  final bool testValido;

  // ── Alertas del Sistema ───────────────────────────────────────────────────
  /// Lista de tipos de riesgo detectados como eliminatorios
  /// Ej: ['Corruptibilidad', 'Agresividad']
  final List<String> alertasRojas;

  /// IDs de grupos donde se detectaron respuestas contradictorias
  /// Ej: ['ETICA_01', 'LID_01']
  final List<String> inconsistenciasDetectadas;

  // ── Estadísticas del Test ─────────────────────────────────────────────────
  final int totalPreguntas;
  final int preguntasRespondidas;
  final int respuestasCorrectas; // Opciones de máximo puntaje elegidas
  final int respuestasIncorrectas;
  final int fallosEscalaMentira;
  final int averageLatencyMs;

  const PersonalityResult({
    required this.scoreFinal,
    required this.diagnosis,
    required this.scoresPorDimension,
    required this.scoreVeracidad,
    required this.testValido,
    required this.alertasRojas,
    required this.inconsistenciasDetectadas,
    required this.totalPreguntas,
    required this.preguntasRespondidas,
    required this.respuestasCorrectas,
    required this.respuestasIncorrectas,
    required this.fallosEscalaMentira,
    this.averageLatencyMs = 0,
  });

  /// Convierte el resultado a un mapa para guardar en SharedPreferences
  Map<String, dynamic> toDetailsMap() {
    return {
      'diagnosis': diagnosis,
      'score_final': scoreFinal,
      'score_veracidad': scoreVeracidad,
      'test_valido': testValido,
      'alertas_rojas': alertasRojas,
      'inconsistencias': inconsistenciasDetectadas,
      'failed_count': respuestasIncorrectas,
      'correct_count': respuestasCorrectas,
      'total_answered': preguntasRespondidas,
      'total_questions': totalPreguntas,
      'min_required': (totalPreguntas * 0.6).ceil(),
      'percentage': preguntasRespondidas > 0
          ? (respuestasCorrectas / preguntasRespondidas * 100).toStringAsFixed(1)
          : '0',
      'progress_to_unlock':
          (preguntasRespondidas / (totalPreguntas * 0.6).ceil()).clamp(0.0, 1.0),
      'scores_por_dimension': scoresPorDimension,
      'average_latency': averageLatencyMs,
    };
  }

  /// Descripción del nivel de veracidad
  String get nivelVeracidad {
    if (scoreVeracidad >= 80) return 'Alta';
    if (scoreVeracidad >= 50) return 'Media';
    return 'Baja';
  }

  /// Color semafórico del score final (para UI)
  String get nivelScore {
    if (scoreFinal >= 85) return 'Excelente';
    if (scoreFinal >= 75) return 'Apto';
    if (scoreFinal >= 55) return 'Deficiente';
    return 'Crítico';
  }
}

import '../models/question.dart';
import '../models/personality_result.dart';

class ScoringEngine {
  static const double umbralApto = 75.0;
  static const int maxFallosMentira = 2;
  static const double umbralPesoCriticoAlerta = 2.5;

  /// Calcula el resultado psicométrico a partir de respuestas en memoria
  static PersonalityResult calculate(List<Question> allQuestions, Map<int, String> answers, {Map<int, int>? latencies}) {
    double puntosTotales = 0;
    double puntosPosibles = 0;
    int correctCount = 0;
    int incorrectCount = 0;
    int fallosMentira = 0;
    int respondidas = 0;

    final Map<String, List<double>> dimScores = {};
    final Map<String, List<double>> inconsistMap = {};
    final Set<String> alertasRojas = {};

    for (final q in allQuestions) {
      final savedAnswer = answers[q.id];
      if (savedAnswer == null) continue;
      respondidas++;

      final puntosObtenidos = q.getPuntosParaOpcion(savedAnswer);
      final maxPuntos = q.puntajeMaximo;
      final esCorrect = savedAnswer == q.correctAnswer;

      final ponderadoObtenido = puntosObtenidos * q.pesoCritico;
      final ponderadoPosible = maxPuntos * q.pesoCritico;
      puntosTotales += ponderadoObtenido;
      puntosPosibles += ponderadoPosible;

      if (esCorrect) {
        correctCount++;
      } else {
        incorrectCount++;
      }

      if (q.esEscalaMentira && puntosObtenidos <= 2) {
        fallosMentira++;
      }

      if (puntosObtenidos == 0 && q.pesoCritico >= umbralPesoCriticoAlerta) {
        if (q.tipoRiesgo.isNotEmpty) {
          alertasRojas.add(q.tipoRiesgo);
        }
      }

      dimScores.putIfAbsent(q.dimension, () => [0, 0]);
      dimScores[q.dimension]![0] += ponderadoObtenido;
      dimScores[q.dimension]![1] += ponderadoPosible;

      if (q.inconsistenciaId != null) {
        final pct = maxPuntos > 0 ? puntosObtenidos / maxPuntos : 0.0;
        inconsistMap.putIfAbsent(q.inconsistenciaId!, () => []);
        inconsistMap[q.inconsistenciaId!]!.add(pct.toDouble());
      }
    }

    final double scoreFinal = puntosPosibles > 0 ? (puntosTotales / puntosPosibles) * 100 : 0;
    final Map<String, double> scoresPorDimension = {};
    dimScores.forEach((dim, vals) {
      scoresPorDimension[dim] = vals[1] > 0 ? (vals[0] / vals[1]) * 100 : 0;
    });

    // Penalización progresiva de veracidad (Sigmoide/Curva ascendente)
    // 0 fallos = 100, 1 fallo = 90, 2 fallos = 70, 3 fallos = 40, 4+ fallos = 0
    // Penalización progresiva de veracidad (Sigmoide/Curva ascendente)
    // 0 fallos = 100, 1 fallo = 90, 2 fallos = 70, 3 fallos = 40, 4+ fallos = 0
    double scoreVeracidadCalculado;
    if (fallosMentira == 0) scoreVeracidadCalculado = 100;
    else if (fallosMentira == 1) scoreVeracidadCalculado = 90;
    else if (fallosMentira == 2) scoreVeracidadCalculado = 70;
    else if (fallosMentira == 3) scoreVeracidadCalculado = 40;
    else scoreVeracidadCalculado = 0;

    // Penalización por Latencia (Audit 4.1)
    int totalLatency = 0;
    int latencyCount = 0;
    if (latencies != null) {
      latencies.forEach((_, ms) {
        totalLatency += ms;
        latencyCount++;
      });
    }
    final int avgLatency = latencyCount > 0 ? (totalLatency ~/ latencyCount) : 0;
    
    // Si la latencia es demasiado baja (< 1.2s) o muy alta (> 8s), penalizamos veracidad
    if (avgLatency > 0) {
      if (avgLatency < 1200) scoreVeracidadCalculado -= 15; // Demasiado rápido (posible "faking good" sin leer)
      if (avgLatency > 8000) scoreVeracidadCalculado -= 10; // Demasiado lento (duda excesiva)
    }
    
    final double scoreVeracidad = scoreVeracidadCalculado.clamp(0, 100).toDouble();
    final bool testValido = fallosMentira <= maxFallosMentira && scoreVeracidad > 30;

    final List<String> inconsistenciasDetectadas = [];
    inconsistMap.forEach((id, pcts) {
      if (pcts.length >= 2) {
        final min = pcts.reduce((a, b) => a < b ? a : b);
        final max = pcts.reduce((a, b) => a > b ? a : b);
        if ((max - min) >= 0.6) {
          inconsistenciasDetectadas.add(id);
        }
      }
    });

    final double scoreFinalAjustado = (scoreFinal - (inconsistenciasDetectadas.length * 5.0)).clamp(0, 100).toDouble();

    String diagnosis;
    final int minRequired = (allQuestions.length * 0.6).ceil();
    final List<String> criticalFailures = [];

    // Validar fallos críticos por dimensión
    scoresPorDimension.forEach((dim, score) {
      final firstQ = allQuestions.firstWhere((q) => q.dimension == dim);
      if (firstQ.pesoCritico >= 2.5 && score < 40.0) {
        criticalFailures.add(dim);
        alertasRojas.add('Fallo Crítico: $dim');
      }
    });

    if (respondidas < minRequired) {
      diagnosis = 'PENDIENTE';
    } else if (!testValido || alertasRojas.isNotEmpty || scoreFinalAjustado < umbralApto || criticalFailures.isNotEmpty) {
      diagnosis = 'INAPTO';
      if (!testValido) alertasRojas.add('Veracidad');
    } else {
      diagnosis = 'APTO';
    }

    return PersonalityResult(
      scoreFinal: scoreFinalAjustado,
      diagnosis: diagnosis,
      scoresPorDimension: scoresPorDimension,
      scoreVeracidad: scoreVeracidad,
      testValido: testValido,
      alertasRojas: alertasRojas.toList(),
      inconsistenciasDetectadas: inconsistenciasDetectadas,
      totalPreguntas: allQuestions.length,
      preguntasRespondidas: respondidas,
      respuestasCorrectas: correctCount,
      respuestasIncorrectas: incorrectCount,
      fallosEscalaMentira: fallosMentira,
      averageLatencyMs: avgLatency,
    );
  }

  /// Detecta si hay una dimensión con alta inconsistencia en tiempo real
  static String? findInconsistentDimension(List<Question> questions, Map<int, String> answers) {
    final Map<String, List<double>> inconsistMap = {};
    
    for (final q in questions) {
      final savedAnswer = answers[q.id];
      if (savedAnswer == null) continue;
      
      if (q.inconsistenciaId != null) {
        final pct = q.puntajeMaximo > 0 ? q.getPuntosParaOpcion(savedAnswer) / q.puntajeMaximo : 0.0;
        inconsistMap.putIfAbsent(q.inconsistenciaId!, () => []);
        inconsistMap[q.inconsistenciaId!]!.add(pct.toDouble());
      }
    }

    for (final entry in inconsistMap.entries) {
      final pcts = entry.value;
      if (pcts.length >= 2) {
        final min = pcts.reduce((a, b) => a < b ? a : b);
        final max = pcts.reduce((a, b) => a > b ? a : b);
        if ((max - min) >= 0.7) { // Umbral de alerta inmediata
          // Retornar la dimensión de la primera pregunta de este grupo
          return questions.firstWhere((q) => q.inconsistenciaId == entry.key).dimension;
        }
      }
    }
    return null;
  }

  static List<String> getLearningPathway(Map<String, double> scores) {
    final List<String> pathway = [];
    final sorted = scores.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    
    for (var entry in sorted.take(3)) {
      if (entry.value < 70) {
        pathway.add(_getConceptForDimension(entry.key));
      }
    }
    
    return pathway;
  }

  static String _getConceptForDimension(String dim) {
    final map = {
      'Etica e Integridad': 'Estudiar la diferencia entre "lealtad mal entendida" y "ética profesional".',
      'Sinceridad': 'Practicar la auto-aceptación. Los baremos PNP detectan la perfección fingida.',
      'Control de Impulsos': 'Técnicas de respiración táctica y mediación de conflictos verbales.',
      'Disciplina': 'Revisar la Ley de Régimen Disciplinario de la PNP (DL 1267).',
      'Relaciones Interpersonales': 'Enfoque en Comunicación Asertiva y trabajo bajo mando jerárquico.',
    };
    return map[dim] ?? 'Revisar los fundamentos básicos de esta dimensión en el reglamento institucional.';
  }
}

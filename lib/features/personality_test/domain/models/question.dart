class Question {
  final int id;
  final String text;
  final Map<String, String> options;
  final Map<String, int> puntosOpciones;
  final String hint;
  final String dimension;
  final String subDimension;
  final bool esEscalaMentira;
  final String? inconsistenciaId;
  final bool esReversa;
  final double pesoCritico;
  final String tipoRiesgo;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.puntosOpciones,
    this.hint = '',
    this.dimension = 'General',
    this.subDimension = '',
    this.esEscalaMentira = false,
    this.inconsistenciaId,
    this.esReversa = false,
    required this.pesoCritico,
    this.tipoRiesgo = '',
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    // Manejo de puntos (asegurar que sean int)
    final Map<String, dynamic> rawPuntos = json['puntos_opciones'] ?? json['puntosOpciones'] ?? {};
    final puntosMap = rawPuntos.map((k, v) => MapEntry(k, (v as num).toInt()));

    return Question(
      id: (json['pregunta_id'] ?? json['id'] ?? 0 as num).toInt(),
      text: json['texto'] ?? json['text'] ?? '',
      options: Map<String, String>.from(json['opciones'] ?? json['options'] ?? {}),
      puntosOpciones: puntosMap,
      dimension: json['dimension'] ?? 'General',
      subDimension: json['sub_dimension'] ?? '',
      esEscalaMentira: json['es_escala_mentira'] ?? false,
      inconsistenciaId: json['inconsistencia_id'] ?? json['inconsistenciaId'],
      esReversa: json['es_reversa'] ?? false,
      pesoCritico: (json['peso_critico'] ?? json['pesoCritico'] ?? 1.0 as num).toDouble(),
      tipoRiesgo: json['tipo_riesgo'] ?? json['tipoRiesgo'] ?? '',
      hint: json['pista'] ?? json['hint'] ?? '',
    );
  }

  // La respuesta "correcta" es la de mayor puntaje
  String get correctAnswer {
    if (puntosOpciones.isEmpty) return 'A';
    final entries = puntosOpciones.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  int get puntajeMaximo {
    if (puntosOpciones.isEmpty) return 10;
    return puntosOpciones.values.reduce((a, b) => a > b ? a : b);
  }

  int getPuntosParaOpcion(String opcionKey) {
    return puntosOpciones[opcionKey] ?? 0;
  }

  double get contribucionMaxima => puntajeMaximo * pesoCritico;
}

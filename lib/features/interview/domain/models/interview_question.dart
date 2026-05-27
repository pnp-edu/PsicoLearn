class InterviewQuestion {
  final int id;
  final String categoria;
  final String pregunta;
  final String puntosClave;
  final String respuestaIdeal;

  InterviewQuestion({
    required this.id,
    required this.categoria,
    required this.pregunta,
    required this.puntosClave,
    required this.respuestaIdeal,
  });

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) {
    return InterviewQuestion(
      id: json['id'],
      categoria: json['categoria'] ?? 'GENERAL',
      pregunta: json['pregunta'],
      puntosClave: json['puntos_clave'],
      respuestaIdeal: json['respuesta_ideal'],
    );
  }
}

class SpatialQuestion {
  final int id;
  final String titulo;
  final String instruccion;
  final String secuenciaAsset; // SVG de la secuencia/problema
  final Map<String, String> opcionesAsset; // clave → ruta SVG de la opción
  final String correcta;
  final String explicacion;
  final String tipo; // 'rotacion', 'serie', 'conteo', etc.

  const SpatialQuestion({
    required this.id,
    required this.titulo,
    required this.instruccion,
    required this.secuenciaAsset,
    required this.opcionesAsset,
    required this.correcta,
    required this.explicacion,
    required this.tipo,
  });
}

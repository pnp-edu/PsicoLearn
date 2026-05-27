import 'package:flutter/material.dart';

class ResultAlerts extends StatelessWidget {
  final List<String> alertasRojas;
  final List<String> inconsistencias;

  const ResultAlerts({
    super.key,
    required this.alertasRojas,
    required this.inconsistencias,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (alertasRojas.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'ALERTAS ELIMINATORIAS',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: alertasRojas
                      .map((a) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      Colors.redAccent.withOpacity(0.4)),
                            ),
                            child: Text(a,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                )),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (inconsistencias.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows_rounded,
                    color: Colors.orange, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Se detectaron ${inconsistencias.length} inconsistencia(s) entre tus respuestas. Esto puede afectar la validez del diagnóstico.',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

import json
import os

os.makedirs('assets/data', exist_ok=True)

dimensiones = ['Sociabilidad', 'Estabilidad Emocional', 'Disciplina', 'Valores', 'Liderazgo', 'Tolerancia al Estrés']

preguntas = []
for i in range(1, 151):
    preguntas.append({
        "id": i,
        "texto": f"Pregunta {i}: ¿Consideras que tu nivel de {dimensiones[i % len(dimensiones)].lower()} es adecuado para la institución?",
        "opciones": {"A": "Totalmente de acuerdo", "B": "Parcialmente de acuerdo", "C": "En desacuerdo", "D": "Totalmente en desacuerdo"},
        "puntos_opciones": {"A": 10, "B": 7, "C": 3, "D": 0},
        "dimension": dimensiones[i % len(dimensiones)],
        "peso_critico": 1.0 + (i % 3) * 0.5,
        "hint": "Esta pregunta evalúa tu idoneidad para el puesto policial.",
        "es_escala_mentira": i % 10 == 0
    })

with open('assets/data/preguntas.json', 'w', encoding='utf-8') as f:
    json.dump({"preguntas": preguntas}, f, ensure_ascii=False, indent=2)

categorias = ['GENERAL', 'MOTIVACIÓN', 'LIDERAZGO', 'SITUACIONAL', 'TOMA DE DECISIONES']

entrevista = []
for i in range(1, 41):
    entrevista.append({
        "id": i,
        "categoria": categorias[i % len(categorias)],
        "pregunta": f"¿Cómo manejarías una situación que requiere {categorias[i % len(categorias)].lower()} bajo alta presión?",
        "puntos_clave": "Mantener la calma, aplicar el protocolo, proteger la vida humana.",
        "respuesta_ideal": "Evaluando rápidamente el escenario, aplicando los protocolos de la PNP con disciplina y manteniendo siempre el respeto por los derechos humanos."
    })

with open('assets/data/entrevista.json', 'w', encoding='utf-8') as f:
    json.dump({"preguntas_entrevista": entrevista}, f, ensure_ascii=False, indent=2)

print("Data generated successfully!")

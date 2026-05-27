# Informe de Auditoría Avanzada: PsicoLearn
**Fecha:** 10 de mayo de 2026
**Objetivo:** Optimización de arquitectura, seguridad psicométrica y experiencia de usuario.

---

## 1. Análisis de Arquitectura y Código

### 1.1. Gestión de Estado y Persistencia
- **Hallazgo:** El uso intensivo de `SharedPreferences` en `TestController` para guardar cada respuesta individualmente (`_saveAnswer`) puede causar cuellos de botella de E/S (I/O) en dispositivos de gama baja, especialmente en tests de 100 preguntas.
- **Riesgo:** Lag en la UI al seleccionar opciones rápidamente.
- **Mejora Sugerida:** Implementar un **Patrón de Repositorio** con una base de datos local más robusta (como **Isar** o **Hive**) o, al menos, realizar guardados en lote (batch) o usar un búfer en memoria antes de persistir.

### 1.2. Acoplamiento de Lógica de Negocio
- **Hallazgo:** `TestController` mezcla carga de datos (assets), lógica de cálculo y persistencia.
- **Mejora Sugerida:** Separar en:
    - `QuestionRepository`: Solo carga y filtrado de datos.
    - `ScoringEngine`: Lógica pura de cálculo psicométrico (testable unitariamente).
    - `TestBloc/Provider`: Manejo del estado de la UI.

---

## 2. Auditoría de Seguridad Psicométrica (Core del Negocio)

### 2.1. Vulnerabilidad de "Hot Restart"
- **Hallazgo:** En `main.dart`, si el plugin de `SharedPreferences` falla, el sistema redirige por defecto a `WelcomeScreen`.
- **Riesgo:** Un usuario astuto podría intentar manipular el estado del test forzando reinicios.
- **Mejora Sugerida:** Implementar un sistema de **Checksum/Integridad** en los resultados guardados para evitar que el usuario edite manualmente los archivos de la app para "aprobar".

### 2.2. Sesgo en la Escala de Mentira
- **Hallazgo:** La lógica actual penaliza con -25 puntos fijos por cada fallo en la escala de mentira.
- **Mejora Sugerida:** Implementar una **Penalización Progresiva**. El primer fallo puede ser una distracción, pero el tercero indica un patrón claro de falta de veracidad. Usar una curva sigmoide para el `scoreVeracidad`.

---

## 3. Experiencia de Usuario (UX) Avanzada

### 3.1. El "Cronómetro Fantasma"
- **Hallazgo:** El cronómetro solo aparece en fases específicas (inicio, mitad, final). Esto es excelente para reducir la ansiedad, pero la transición es brusca.
- **Mejora Sugerida:** Usar un **indicador de "Pulso de Tiempo"** sutil (un gradiente que se mueve muy lento en el borde de la pantalla) en lugar de ocultarlo totalmente. Esto mantiene la noción de urgencia sin el estrés del segundero constante.

### 3.2. Feedback de Errores ("Escuelita")
- **Hallazgo:** La pantalla de resultados (`ResultScreen`) procesa strings de JSON en la UI (`json.decode(rawDimScores)`).
- **Riesgo:** Errores de renderizado si el JSON está mal formado.
- **Mejora Sugerida:** El `TestController` debe entregar siempre objetos de dominio ya procesados. Nunca delegar el `json.decode` a la capa de presentación.

---

## 4. Sugerencias "Más allá de lo común"

### 4.1. Análisis de Latencia de Respuesta (Bio-feedback implícito)
- **Propuesta:** Medir el tiempo que el usuario tarda en responder cada pregunta. 
- **Por qué:** En psicología, una respuesta demasiado rápida o demasiado lenta en preguntas críticas puede indicar duda o intento de manipulación (faking). Podrías añadir un `score_latencia` al diagnóstico final.

### 4.2. Generación de Reporte PDF Dinámico
- **Propuesta:** Permitir al usuario exportar su diagnóstico.
- **Técnica:** Usar el paquete `pdf` para generar un informe visualmente atractivo con los gráficos de `fl_chart` incluidos.

### 4.3. Inyección de Preguntas de Control Dinámicas
- **Propuesta:** Si el sistema detecta inconsistencias en tiempo real, inyectar una pregunta de control adicional para validar la dimensión en duda antes de terminar el test.

---

## 5. Conclusión de Auditoría
El proyecto tiene una base sólida y una lógica psicométrica bien pensada (especialmente el manejo de pesos críticos y dimensiones). La principal deuda técnica es la **dispersión de responsabilidades** en el controlador y la dependencia de **SharedPreferences** para lógica compleja.

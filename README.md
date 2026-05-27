# Psicolearn PNP 👮‍♂️🧠

Plataforma avanzada de preparación psicométrica y entrevista personal para postulantes a la Policía Nacional del Perú (PNP).

## 🚀 Arquitectura del Proyecto

El proyecto sigue los principios de **Clean Architecture** orientada a **Features**, lo que permite una escalabilidad robusta y un mantenimiento sencillo.

### 📁 Estructura de Directorios

- `lib/core/`: Componentes transversales (Temas, DI, Servicios Globales).
- `lib/features/`: Módulos independientes de la aplicación:
  - `personality_test/`: Simulador de test de personalidad con feedback en tiempo real.
  - `spatial_test/`: Evaluación de razonamiento espacial (figuras, cubos, etc.).
  - `interview/`: Simulador táctico de entrevista personal con modo realismo.
  - `home/`: Dashboard principal y gestión de ajustes.
  - `results/`: Motores de diagnóstico y visualización de progreso.

### 🛠 Estructura de un Módulo (Feature)

Cada módulo se divide en tres capas principales:
1. **Data**: Repositorios, fuentes de datos (JSON/Hive) y modelos de datos.
2. **Domain**: Lógica de negocio pura, controladores y entidades.
3. **Presentation**: Widgets, pantallas y gestión de estado de UI.

## 🛠 Estándares de Desarrollo

- **Linter Estricto**: Configurado en `analysis_options.yaml` para asegurar código limpio y consistente.
- **Inyección de Dependencias**: Uso de `get_it` para desacoplar componentes.
- **Persistencia**: Implementada con `Hive` para un rendimiento óptimo en dispositivos móviles.

## 📦 Assets y Datos

Los bancos de preguntas y recursos visuales se organizan en:
- `assets/data/`: Archivos JSON maestros para los tests.
- `assets/images/`: Recursos gráficos y figuras espaciales.
- `assets/lottie/`: Animaciones interactivas premium.

---
*Optimizado para análisis de IA mediante [AI_README.md](AI_README.md).*


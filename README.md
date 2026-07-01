# 🧩 Vera

**Una app para acompañar a padres y cuidadores durante crisis (meltdowns) de niños en el espectro autista.**

Vera combina inteligencia artificial en el dispositivo, dictado por voz y seguimiento de patrones para dar apoyo en el momento exacto en que más se necesita: durante una crisis. Todo funciona 100% local, sin conexión a servidores externos.

---

## 📱 Sobre el proyecto

Cuando un niño autista tiene un meltdown, los padres necesitan pasos claros y rápidos, no que buscar en internet ni recordar teoría. Vera resuelve esto con un **Modo Crisis** guiado: el cuidador describe lo que está pasando (por texto o por voz), un modelo de machine learning clasifica el tipo de episodio, y la app despliega instrucciones paso a paso, con opción de lectura en voz alta para tener las manos libres.

Con el tiempo, Vera también ayuda a identificar patrones — desencadenantes frecuentes, horarios pico, estrategias que sí funcionan — para que cada crisis futura se pueda anticipar mejor.

---

## ✨ Funcionalidades principales

### 🚨 Modo Crisis
- Descripción de la situación por **texto o dictado de voz** (`Speech` framework, es-MX).
- Clasificación automática del tipo de meltdown mediante un modelo de **Core ML** entrenado, con respaldo (fallback) usando `NaturalLanguage` (lematización + embeddings semánticos en español).
- Guía paso a paso adaptada al tipo detectado (sobreestimulación, frustración, cansancio o cambio de rutina).
- **Lectura en voz alta** de cada paso con `AVSpeechSynthesizer`, para poder usar la app sin mirar la pantalla.
- Opción de registrar el episodio al finalizar, para retroalimentar el seguimiento.

### 📊 Seguimiento y análisis
- Registro detallado de episodios: desencadenantes, comportamientos, estrategias de calma, intensidad y duración.
- Vista de **calendario** con episodios por día.
- Panel de **análisis** con distribución por tipo, desencadenantes más comunes, patrón semanal e insights automáticos generados a partir del historial.

### 👤 Perfil del niño
- Datos personalizables: nombre, edad, desencadenantes conocidos y estrategias efectivas.
- Las sugerencias de la app se personalizan combinando lo aprendido del perfil con las recomendaciones base por tipo de crisis.

### 🔒 Privacidad primero
- Todos los datos se almacenan **localmente** en el dispositivo con SwiftData — nada se envía a servidores externos.
- La clasificación con IA corre completamente **on-device** (Core ML + NaturalLanguage).

---

## 🛠️ Stack técnico

| Área | Tecnología |
|---|---|
| UI | SwiftUI |
| Persistencia | SwiftData |
| Machine Learning | Core ML (`MeltdownClassifier.mlmodel`) + `NaturalLanguage` framework |
| Voz | `Speech` framework (STT) + `AVFoundation` / `AVSpeechSynthesizer` (TTS) |
| Arquitectura | MVVM ligero con servicios singleton (`MLService`, `SuggestionService`, `DataService`) |

---

## 🗂️ Estructura del proyecto

```
Vera/
├── VeraApp.swift            # Entry point, configuración de ModelContainer (SwiftData)
├── ContentView.swift        # TabView principal (Inicio, Calendario, Seguimiento, Análisis, Perfil)
│
├── Views/
│   ├── HomeView.swift        # Pantalla principal + botón de crisis
│   ├── CrisisModeView.swift  # Flujo guiado de Modo Crisis (input → pasos → resumen)
│   ├── TrackView.swift       # Registro manual de episodios
│   ├── CalendarView.swift    # Vista de calendario mensual con episodios
│   ├── AnalysisView.swift    # Estadísticas, gráficas e insights
│   ├── ProfileView.swift     # Perfil del niño y configuración
│   └── Components.swift      # Componentes de UI reutilizables
│
├── Models/
│   └── AppModels.swift       # MeltdownEvent, ChildProfile, LearnedStrategy (SwiftData)
│
├── Domain/
│   └── DomainEnums.swift     # MeltdownType, Trigger, Behavior, CalmingStrategy, Intensity
│
├── Services/
│   ├── AppServices.swift     # MLService, SuggestionService, DataService
│   └── SpeechManager.swift   # Manejo de STT/TTS
│
├── Theme.swift               # Design tokens (colores, tipografía, espaciado)
└── MeltdownClassifier.mlmodel
```

---

## 🧠 Cómo funciona la clasificación

1. **Modelo Core ML entrenado** (`MeltdownClassifier.mlmodelc`): primera opción si está compilado en el bundle.
2. **Fallback con NaturalLanguage**: si el modelo no está disponible, se combinan:
   - Lematización de palabras clave por categoría.
   - Similitud semántica (embeddings de español) contra palabras "ancla" de cada tipo de crisis.

Los cuatro tipos que reconoce la app:

| Tipo | Ejemplos de señales |
|---|---|
| 🔊 Sobreestimulación | ruido, luces, multitudes, texturas |
| ⛈️ Frustración | no poder comunicarse, tareas bloqueadas |
| 😴 Cansancio | falta de sueño, agotamiento |
| 🔁 Cambio de rutina | horarios alterados, sorpresas, imprevistos |

---

## 🚀 Cómo correr el proyecto

1. Clona el repositorio.
2. Ábrelo en **Xcode 15+**.
3. Selecciona un simulador o dispositivo físico con **iOS 17+**.
4. Ejecuta con `Cmd + R`.

> ⚠️ El reconocimiento de voz y algunas funciones de audio requieren un **dispositivo físico** para pruebas completas (el simulador no expone un micrófono real).

---

## 🎯 Motivación

Este proyecto nace de una necesidad real: dar a los padres de niños autistas una herramienta rápida, silenciosa y sin fricción en los momentos más difíciles, cuando cada segundo y cada decisión cuentan. Vera no reemplaza el acompañamiento profesional, pero busca ser un apoyo inmediato y basado en patrones reales del niño.

---

## 📌 Estado del proyecto

En desarrollo activo — construido como proyecto de impacto social por **Liss** ([@Lissel15](https://github.com/Lissel15)), estudiante de Ingeniería en Sistemas Computacionales en UDLAP.

---

## 📄 Licencia

Por definir.

# Interval Timer

App de entrenamiento por intervalos (HIIT/Tabata) para iOS, construida con SwiftUI.

## Características

- **5 fases de entrenamiento**: Preparación, Trabajo, Descanso, Enfriamiento, Completado
- **Timer preciso**: Motor basado en Combine con `Timer.publish`
- **UI de alto contraste**: Números gigantes y colores vibrantes por fase
- **Feedback háptico**: Vibraciones contextuales en countdown y transiciones
- **Audio**: Sonidos distintivos para cada cambio de fase
- **Soporte background**: El timer continúa con la pantalla bloqueada
- **Persistencia**: La configuración se guarda automáticamente

## Capturas de Pantalla

| Preparación | Trabajo | Descanso | Configuración |
|-------------|---------|----------|---------------|
| Amarillo | Verde | Rojo | Lista nativa |

## Arquitectura

```
IntervalTimer/
├── App/
│   └── AppMain.swift              # Punto de entrada
├── Models/
│   └── TimerConfig.swift          # Configuración + presets
├── ViewModels/
│   ├── TimerManager.swift         # Motor principal (Combine)
│   └── TimerViewModel.swift       # Legacy (compatibilidad)
├── Views/
│   ├── TimerDisplayView.swift     # Pantalla principal
│   ├── ConfigurationView.swift    # Ajustes
│   └── ...
└── Services/
    ├── HapticManager.swift        # Feedback táctil
    └── AudioManager.swift         # Audio + background
```

### Patrones Utilizados

- **MVVM**: Separación clara entre Vista y lógica
- **State Pattern**: Estados del timer (`idle`, `running`, `paused`, `finished`)
- **Singleton**: Managers de audio y haptics
- **Combine**: Streams reactivos para el timer

## Stack Técnico

| Componente | Tecnología |
|------------|------------|
| UI | SwiftUI |
| Timer | Combine (`Timer.publish`) |
| Audio | AVFoundation |
| Haptics | UIKit (`UIImpactFeedbackGenerator`) |
| Persistencia | UserDefaults + Codable |
| Tests | XCTest |

## Requisitos

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Instalación

```bash
git clone <repo-url>
cd IntervalTimer
open IntervalTimer.xcodeproj
```

Ejecuta en simulador o dispositivo desde Xcode.

## Configuración por Defecto (Tabata Clásico)

| Parámetro | Valor |
|-----------|-------|
| Preparación | 10 seg |
| Trabajo | 20 seg |
| Descanso | 10 seg |
| Rondas | 8 |
| Enfriamiento | 30 seg |

## Presets Incluidos

- `tabataClassic`: 20s trabajo / 10s descanso / 8 rondas
- `hiitStandard`: 40s trabajo / 20s descanso / 6 rondas
- `beginner`: 20s trabajo / 20s descanso / 4 rondas
- `advanced`: 45s trabajo / 15s descanso / 10 rondas

## Tests

```bash
# Unit tests
xcodebuild test -scheme IntervalTimer -destination 'platform=iOS Simulator,name=iPhone 16'

# Solo tests unitarios
xcodebuild test -scheme IntervalTimer -only-testing:IntervalTimerTests
```

## Background Mode

Para que el timer funcione con la pantalla bloqueada:

1. Abre el proyecto en Xcode
2. Selecciona el target `IntervalTimer`
3. Ve a **Signing & Capabilities**
4. Agrega **Background Modes**
5. Activa **Audio, AirPlay, and Picture in Picture**

## Licencia

MIT

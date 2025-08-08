/*
Propósito:
- Contiene todos los parámetros configurables de un entrenamiento
- Actúa como única fuente para la configuración

1. Valores predeterminados para inicio rápido
2. Cálculos derivados para visualización
*/


import Foundation

struct TimerConfig: Codable, Hashable {
    var prepSeconds: Int = 5
    var workSeconds: Int = 30
    var restSeconds: Int = 10
    var rounds: Int = 8
    var cooldownSeconds: Int = 30
    
    var prepDisplay: String { "\(prepSeconds) s" }
    var workDisplay: String {
        workSeconds < 60 ? "\(workSeconds) s" : String(format: "%d:%02d", workSeconds / 60, workSeconds % 60)
    }
    var restDisplay: String {
        restSeconds < 60 ? "\(restSeconds) s" : String(format: "%d:%02d", restSeconds / 60, restSeconds % 60)
    }
    var roundsDisplay: String { "\(rounds)" }
    var cooldownDisplay: String {
        cooldownSeconds < 60 ? "\(cooldownSeconds) s" : String(format: "%d:%02d", cooldownSeconds / 60, cooldownSeconds % 60)
    }
}

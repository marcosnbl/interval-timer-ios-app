/*
 TimerConfig.swift

 Propósito:
 - Modelo de datos para la configuración del entrenamiento
 - Codable para persistencia en UserDefaults
 - Valores por defecto optimizados para Tabata clásico

 Configuración Tabata estándar:
 - 20 segundos de trabajo intenso
 - 10 segundos de descanso
 - 8 rondas (4 minutos total)
*/

import Foundation

struct TimerConfig: Codable, Hashable, Equatable {

    // MARK: - Properties

    var prepSeconds: Int = 10
    var workSeconds: Int = 20
    var restSeconds: Int = 10
    var rounds: Int = 8
    var cooldownSeconds: Int = 30

    // MARK: - Display Formatters

    var prepDisplay: String {
        formatTime(prepSeconds)
    }

    var workDisplay: String {
        formatTime(workSeconds)
    }

    var restDisplay: String {
        formatTime(restSeconds)
    }

    var roundsDisplay: String {
        "\(rounds)"
    }

    var cooldownDisplay: String {
        if cooldownSeconds == 0 {
            return "Ninguno"
        }
        return formatTime(cooldownSeconds)
    }

    // MARK: - Computed Properties

    /// Duración total del entrenamiento en segundos
    var totalDuration: Int {
        prepSeconds +
        (workSeconds * rounds) +
        (restSeconds * max(0, rounds - 1)) +
        cooldownSeconds
    }

    /// Duración total formateada (MM:SS)
    var totalDurationDisplay: String {
        formatTime(totalDuration)
    }

    // MARK: - Private Helpers

    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) s"
        }
        let min = seconds / 60
        let sec = seconds % 60
        if sec == 0 {
            return "\(min) min"
        }
        return String(format: "%d:%02d", min, sec)
    }
}

// MARK: - Presets

extension TimerConfig {
    /// Configuración Tabata clásica (4 min)
    static let tabataClassic = TimerConfig(
        prepSeconds: 10,
        workSeconds: 20,
        restSeconds: 10,
        rounds: 8,
        cooldownSeconds: 30
    )

    /// HIIT estándar (intervalos más largos)
    static let hiitStandard = TimerConfig(
        prepSeconds: 10,
        workSeconds: 40,
        restSeconds: 20,
        rounds: 6,
        cooldownSeconds: 60
    )

    /// Principiante
    static let beginner = TimerConfig(
        prepSeconds: 15,
        workSeconds: 20,
        restSeconds: 20,
        rounds: 4,
        cooldownSeconds: 60
    )

    /// Avanzado
    static let advanced = TimerConfig(
        prepSeconds: 5,
        workSeconds: 45,
        restSeconds: 15,
        rounds: 10,
        cooldownSeconds: 30
    )
}

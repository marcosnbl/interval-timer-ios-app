/*
 HapticManager.swift

 Propósito:
 - Gestionar feedback háptico centralizado
 - Proporciona diferentes intensidades para distintos eventos
 - Optimizado para rendimiento (lazy initialization)

 Patrón: Singleton con APIs tipadas
*/

import UIKit

final class HapticManager {
    static let shared = HapticManager()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        prepareGenerators()
    }

    private func prepareGenerators() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
    }

    // MARK: - Countdown Haptics

    /// Haptic suave para cada segundo normal
    func tick() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    /// Haptic medio para los últimos 3 segundos
    func countdownWarning() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    /// Haptic fuerte para transición de fase
    func phaseTransition() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }

    // MARK: - Notification Haptics

    /// Notificación de éxito (workout completado)
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    /// Notificación de warning (pausa)
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    /// Notificación de error
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    // MARK: - Countdown Sequence

    /// Ejecuta haptic apropiado según segundos restantes
    func countdownHaptic(for seconds: Int) {
        switch seconds {
        case 1...3:
            countdownWarning()
        case 0:
            phaseTransition()
        default:
            break // Sin haptic para segundos normales (opcional: tick())
        }
    }
}

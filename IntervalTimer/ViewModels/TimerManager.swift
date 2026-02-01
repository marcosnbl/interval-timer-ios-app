/*
 TimerManager.swift

 Propósito:
 - Motor de tiempo preciso usando Combine (Timer.publish)
 - Gestión de estados con State Pattern
 - Sincronización con background/foreground
 - Persistencia de configuración automática

 Arquitectura:
 - Usa Timer.publish(every: 1, on: .main, in: .common) para precisión
 - Guarda timestamp al ir a background para recalcular al volver
 - Integra HapticManager y AudioManager

 Patrón: MVVM + State Pattern
*/

import Foundation
import Combine
import SwiftUI

// MARK: - Phase State Pattern

enum TimerPhase: String, CaseIterable, Codable {
    case prep
    case work
    case rest
    case cooldown
    case done

    var displayName: String {
        switch self {
        case .prep:     return "PREPÁRATE"
        case .work:     return "¡TRABAJO!"
        case .rest:     return "DESCANSO"
        case .cooldown: return "ENFRIAMIENTO"
        case .done:     return "¡COMPLETADO!"
        }
    }

    var color: Color {
        switch self {
        case .prep:     return Color(red: 1.0, green: 0.8, blue: 0.0) // Amarillo vibrante
        case .work:     return Color(red: 0.0, green: 0.85, blue: 0.35) // Verde neón
        case .rest:     return Color(red: 0.95, green: 0.25, blue: 0.25) // Rojo intenso
        case .cooldown: return Color(red: 0.4, green: 0.6, blue: 1.0) // Azul frío
        case .done:     return Color(red: 1.0, green: 0.6, blue: 0.0) // Naranja celebración
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .prep:
            return [
                Color(red: 1.0, green: 0.85, blue: 0.0),
                Color(red: 1.0, green: 0.65, blue: 0.0)
            ]
        case .work:
            return [
                Color(red: 0.0, green: 0.9, blue: 0.4),
                Color(red: 0.0, green: 0.7, blue: 0.3)
            ]
        case .rest:
            return [
                Color(red: 1.0, green: 0.2, blue: 0.2),
                Color(red: 0.8, green: 0.1, blue: 0.15)
            ]
        case .cooldown:
            return [
                Color(red: 0.3, green: 0.5, blue: 1.0),
                Color(red: 0.2, green: 0.35, blue: 0.85)
            ]
        case .done:
            return [
                Color(red: 1.0, green: 0.7, blue: 0.0),
                Color(red: 1.0, green: 0.5, blue: 0.0)
            ]
        }
    }
}

// MARK: - Timer State

enum TimerState {
    case idle
    case running
    case paused
    case finished
}

// MARK: - Timer Manager

@MainActor
final class TimerManager: ObservableObject {

    // MARK: - Published Properties

    @Published var phase: TimerPhase = .prep
    @Published var remainingSeconds: Int = 5
    @Published var currentRound: Int = 1
    @Published var state: TimerState = .idle
    @Published var config: TimerConfig {
        didSet { saveConfig() }
    }

    // MARK: - Computed Properties

    var totalRounds: Int { config.rounds }

    var progress: Double {
        let total = totalSecondsForPhase(phase)
        guard total > 0 else { return 0 }
        return Double(total - remainingSeconds) / Double(total)
    }

    var isRunning: Bool { state == .running }
    var isPaused: Bool { state == .paused }
    var isFinished: Bool { state == .finished }
    var canStart: Bool { state == .idle || state == .finished }

    // MARK: - Private Properties

    private var timerCancellable: AnyCancellable?
    private var backgroundTimestamp: Date?
    private var backgroundRemainingSeconds: Int = 0

    private let haptics = HapticManager.shared
    private let audio = AudioManager.shared

    // MARK: - Persistence Keys

    private let configKey = "IntervalTimer.config"

    // MARK: - Initialization

    init() {
        self.config = Self.loadConfig()
        self.remainingSeconds = config.prepSeconds
        setupNotifications()
    }

    // MARK: - Timer Control

    func start() {
        guard canStart else { return }

        if state == .finished {
            reset()
        }

        state = .running
        audio.startBackgroundAudio()
        startTimer()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        timerCancellable?.cancel()
        haptics.warning()
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        startTimer()
    }

    func reset() {
        timerCancellable?.cancel()
        state = .idle
        phase = .prep
        currentRound = 1
        remainingSeconds = config.prepSeconds
        audio.stopBackgroundAudio()
    }

    func toggle() {
        switch state {
        case .idle, .finished:
            start()
        case .running:
            pause()
        case .paused:
            resume()
        }
    }

    // MARK: - Timer Engine (Combine)

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        // Haptic feedback para countdown
        if remainingSeconds <= 3 && remainingSeconds > 0 {
            haptics.countdownWarning()
        }

        remainingSeconds -= 1

        if remainingSeconds <= 0 {
            transitionToNextPhase()
        }
    }

    // MARK: - Phase Transitions

    private func transitionToNextPhase() {
        haptics.phaseTransition()

        switch phase {
        case .prep:
            enterPhase(.work, seconds: config.workSeconds, sound: .start)

        case .work:
            if currentRound < config.rounds {
                enterPhase(.rest, seconds: config.restSeconds, sound: .rest)
            } else if config.cooldownSeconds > 0 {
                enterPhase(.cooldown, seconds: config.cooldownSeconds, sound: .cooldown)
            } else {
                finishWorkout()
            }

        case .rest:
            currentRound += 1
            enterPhase(.work, seconds: config.workSeconds, sound: .start)

        case .cooldown:
            finishWorkout()

        case .done:
            break
        }
    }

    private func enterPhase(_ newPhase: TimerPhase, seconds: Int, sound: TimerSound) {
        phase = newPhase
        remainingSeconds = seconds
        audio.play(sound)
    }

    private func finishWorkout() {
        timerCancellable?.cancel()
        phase = .done
        state = .finished
        remainingSeconds = 0
        audio.play(.finish)
        audio.stopBackgroundAudio()
        haptics.success()
    }

    // MARK: - Background/Foreground Handling

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleEnterBackground()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleEnterForeground()
        }
    }

    private func handleEnterBackground() {
        guard state == .running else { return }
        backgroundTimestamp = Date()
        backgroundRemainingSeconds = remainingSeconds
    }

    private func handleEnterForeground() {
        guard state == .running,
              let timestamp = backgroundTimestamp else { return }

        let elapsed = Int(Date().timeIntervalSince(timestamp))
        simulateElapsedTime(elapsed)
        backgroundTimestamp = nil
    }

    /// Simula el paso del tiempo mientras la app estaba en background
    private func simulateElapsedTime(_ seconds: Int) {
        var remaining = seconds
        var currentRemaining = backgroundRemainingSeconds

        while remaining > 0 && state == .running {
            if remaining >= currentRemaining {
                remaining -= currentRemaining
                currentRemaining = 0
                advancePhase()
                currentRemaining = remainingSeconds
            } else {
                currentRemaining -= remaining
                remaining = 0
            }
        }

        if state == .running {
            remainingSeconds = currentRemaining
        }
    }

    private func advancePhase() {
        switch phase {
        case .prep:
            phase = .work
            remainingSeconds = config.workSeconds

        case .work:
            if currentRound < config.rounds {
                phase = .rest
                remainingSeconds = config.restSeconds
            } else if config.cooldownSeconds > 0 {
                phase = .cooldown
                remainingSeconds = config.cooldownSeconds
            } else {
                finishWorkout()
            }

        case .rest:
            currentRound += 1
            phase = .work
            remainingSeconds = config.workSeconds

        case .cooldown:
            finishWorkout()

        case .done:
            break
        }
    }

    // MARK: - Helpers

    private func totalSecondsForPhase(_ phase: TimerPhase) -> Int {
        switch phase {
        case .prep: return config.prepSeconds
        case .work: return config.workSeconds
        case .rest: return config.restSeconds
        case .cooldown: return config.cooldownSeconds
        case .done: return 0
        }
    }

    // MARK: - Persistence

    private func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
    }

    private static func loadConfig() -> TimerConfig {
        guard let data = UserDefaults.standard.data(forKey: "IntervalTimer.config"),
              let config = try? JSONDecoder().decode(TimerConfig.self, from: data) else {
            return TimerConfig()
        }
        return config
    }

    // MARK: - Config Updates (for ConfigView)

    func updateConfig(_ update: (inout TimerConfig) -> Void) {
        update(&config)
        if state == .idle {
            remainingSeconds = config.prepSeconds
        }
    }
}

// MARK: - Time Formatting Extension

extension TimerManager {
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var roundDisplay: String {
        "RONDA \(currentRound) DE \(totalRounds)"
    }
}

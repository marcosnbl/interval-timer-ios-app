/*
Propósito:
- Gestionar el estado del temporizador
- Coordinar transiciones entre fases
- Proveer datos a la UI

1. Gestión del ciclo de vida del timer (start/pause/resume)
2. Transiciones automáticas entre fases
3. Reproducción de sonido
4. Exposición de estado a la vista

Patrón: MVVM
*/

import Foundation
import AVFoundation

enum Phase: CaseIterable {
    case prep, work, rest, cooldown, done
}

@MainActor
final class TimerViewModel: ObservableObject {
    @Published var config = TimerConfig()
    @Published var currentPhase: Phase = .prep
    @Published var remaining: Int = 5
    @Published var currentRound = 1
    @Published var isPaused = false
    @Published var hasStarted = false
    
    private var timer: Timer?
    private var player: AVAudioPlayer?
    
    init() {
        remaining = config.prepSeconds
        currentPhase = .prep
    }
    
    func start() {
        hasStarted = true
        isPaused = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                self.tick()
            }
        }
    }
    
    func pause() {
        timer?.invalidate()
        isPaused = true
    }
    
    func resume() {
        isPaused = false
        start()
    }
    
    func resetToInitialState() {
        timer?.invalidate()
        currentPhase = .prep
        currentRound = 1
        remaining = config.prepSeconds
        isPaused = false
        hasStarted = false
    }

    private func tick() {
        Task { @MainActor in
            remaining -= 1
            if remaining <= 0 {
                nextPhase()
            }
        }
    }
    
    private func nextPhase() {
        switch currentPhase {
        case .prep:
            transition(to: .work, seconds: config.workSeconds, sound: "start")
            
        case .work:
            if currentRound < config.rounds {
                transition(to: .rest, seconds: config.restSeconds, sound: "rest")
            } else {
                if config.cooldownSeconds > 0 {
                    transition(to: .cooldown, seconds: config.cooldownSeconds, sound: "cooldown")
                } else {
                    finish()
                }
            }
            
        case .rest:
            currentRound += 1
            transition(to: .work, seconds: config.workSeconds, sound: "start")
            
        case .cooldown:
            finish()
                
        case .done:
            break
        }
    }
    
    private func finish() {
        timer?.invalidate()
        currentPhase = .done
        isPaused = false
        hasStarted = false
        playSound(named: "finish")
    }

    private func transition(to phase: Phase, seconds: Int, sound: String) {
        currentPhase = phase
        remaining = seconds
        playSound(named: sound)
    }
    
    private func playSound(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
    
    var displayPhase: String {
        switch currentPhase {
        case .prep:     return "Preparado"
        case .work:     return "Trabajo"
        case .rest:     return "Descanso"
        case .cooldown: return "Enfriamiento"
        case .done:     return "¡Listo!"
        }
    }
}


extension TimerViewModel {
    var mainButtonIcon: String {
        switch (hasStarted, isPaused, currentPhase) {
        case (false, _, _): return "play.fill"
        case (true, true, _): return "play.fill"
        case (true, false, .done): return "arrow.counterclockwise"
        case (true, false, _): return "pause.fill"
        }
    }
    
    var shouldShowSingleButton: Bool {
        currentPhase == .done 
    }
}


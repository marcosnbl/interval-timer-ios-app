/*
 AudioManager.swift

 Propósito:
 - Gestionar reproducción de audio centralizada
 - Configurar AVAudioSession para background playback
 - Mantener el timer activo cuando la app está en segundo plano

 Estrategia Background:
 iOS no permite timers en background, pero SÍ permite audio.
 Configuramos la sesión de audio para que continúe en background,
 lo que mantiene la app activa y el timer funcionando.
*/

import AVFoundation

final class AudioManager {
    static let shared = AudioManager()

    private var player: AVAudioPlayer?
    private var silentPlayer: AVAudioPlayer?

    private init() {
        configureAudioSession()
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback permite reproducción en background
            // .duckOthers reduce volumen de otras apps temporalmente
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("AudioManager: Failed to configure audio session - \(error)")
        }
    }

    // MARK: - Sound Playback

    func play(_ sound: TimerSound) {
        guard let url = Bundle.main.url(forResource: sound.filename, withExtension: "mp3") else {
            print("AudioManager: Sound file not found - \(sound.filename)")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("AudioManager: Failed to play sound - \(error)")
        }
    }

    // MARK: - Background Keep-Alive

    /// Inicia reproducción silenciosa para mantener la app activa en background
    /// Nota: Usa un archivo de sonido existente con volumen mínimo
    func startBackgroundAudio() {
        // Intentamos usar cualquier archivo de sonido disponible con volumen casi inaudible
        // Esto mantiene la sesión de audio activa sin molestar al usuario
        let soundFiles = ["start", "rest", "cooldown", "finish"]

        for filename in soundFiles {
            if let url = Bundle.main.url(forResource: filename, withExtension: "mp3") {
                do {
                    silentPlayer = try AVAudioPlayer(contentsOf: url)
                    silentPlayer?.volume = 0.001 // Prácticamente inaudible
                    silentPlayer?.numberOfLoops = -1 // Loop infinito
                    silentPlayer?.play()
                    return
                } catch {
                    continue
                }
            }
        }

        print("AudioManager: No audio files available for background playback")
    }

    func stopBackgroundAudio() {
        silentPlayer?.stop()
        silentPlayer = nil
    }

    // MARK: - Session Management

    func activateSession() {
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Sound Types

enum TimerSound: String {
    case start
    case rest
    case cooldown
    case finish
    case tick

    var filename: String { rawValue }
}

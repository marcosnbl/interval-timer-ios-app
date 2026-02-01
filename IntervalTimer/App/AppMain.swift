/*
 AppMain.swift

 Propósito:
 - Punto de entrada de la aplicación
 - Configura el ambiente global
 - Inicializa el TimerManager compartido

 Arquitectura: Single source of truth para el estado del timer
*/

import SwiftUI

@main
struct AppMain: App {
    @StateObject private var timerManager = TimerManager()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TimerDisplayView(timer: timerManager)
            }
            .preferredColorScheme(.dark)
        }
    }
}

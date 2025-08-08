/*
Propósito:
- Vista central de la aplicación
- Muestra el estado actual del entrenamiento
- Proporciona controles de inicio/pausa/reinicio
- Coordina la navegación a ConfigView

Flujo Principal:
1. Muestra temporizador y fase actual
2. Reacciona a cambios en el ViewModel
*/

import SwiftUI

struct TimerScreenView: View {
    @StateObject private var vm = TimerViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            ZStack {
                phaseGradient(for: vm.currentPhase)
                    .animation(.easeInOut(duration: 0.4), value: vm.currentPhase)
                
                VStack {
                    HStack {
                        Spacer()
                        NavigationLink {
                            ConfigView(vm: vm)
                                .navigationTitle("Ajustes")
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .accessibilityIdentifier("AjustesButton")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                                .padding(.trailing, 20)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Text(vm.displayPhase)
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        
                        Text(formattedTime(vm.remaining))
                            .font(.system(size: 90, weight: .thin, design: .monospaced))
                            .foregroundStyle(.white)
                        
                        Text("Ronda \(vm.currentRound) / \(vm.config.rounds)")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    if vm.currentPhase == .done {
                        Button {
                            vm.resetToInitialState()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Volver a empezar")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        HStack(spacing: 30) {
                            Button("Reiniciar") {
                                vm.resetToInitialState()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(!vm.hasStarted)
                            
                            Button {
                                vm.isPaused ? vm.resume() : vm.hasStarted ? vm.pause() : vm.start()
                            } label: {
                                Text(vm.isPaused ? "Continuar" : vm.hasStarted ? "Pausar" : "Iniciar")
                                    .accessibilityIdentifier("StartPauseContinueButton")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                }
            }
        }
    }
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline.bold())
                .foregroundColor(.white)
                .padding()
                .frame(minWidth: 120)
                .background(Color.blue.gradient)
                .cornerRadius(10)
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
        }
    }
    
    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline.bold())
                .foregroundColor(.blue)
                .padding()
                .frame(minWidth: 120)
                .background(Color.white)
                .cornerRadius(10)
        }
    }
    
    private func formattedTime(_ total: Int) -> String {
        let safe = max(total, 0)
        let min = safe / 60
        let sec = safe % 60
        return String(format: "%02d:%02d", min, sec)
    }
}

extension View {
    func phaseGradient(for phase: Phase) -> some View {
        let colors: [Color] = {
            switch phase {
            case .prep:     return [.white, .gray]
            case .work:     return [.green, .green.opacity(0.7)]
            case .rest:     return [.blue, .cyan]
            case .cooldown: return [.purple, .indigo]
            case .done:     return [.orange, .yellow]
            }
        }()
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .id(phase)
        .ignoresSafeArea()
    }
}

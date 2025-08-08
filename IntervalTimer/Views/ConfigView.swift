/*
Propósito:
- Vista de configuración modular para el temporizador
- Permite ajustar todos los parámetros del entrenamiento
- Diseño limpio y accesible

1. Usuario selecciona parámetro a editar
2. Se presenta sheet especializado
3. Cambios se guardan automáticamente en TimerViewModel
*/


import SwiftUI

struct ConfigView: View {
    @ObservedObject var vm: TimerViewModel
    
    @State private var activeSheet: ConfigSheetType?
    
    var body: some View {
        List {
            settingsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Configuración")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { sheetType in
            sheetView(for: sheetType)
        }
    }
        
    private var settingsSection: some View {
        Section {
            settingsRow(title: "Preparación", value: vm.config.prepDisplay) {
                activeSheet = .prep
            }
            
            settingsRow(title: "Entrenar", value: vm.config.workDisplay) {
                activeSheet = .work
            }
            
            settingsRow(title: "Descansar", value: vm.config.restDisplay) {
                activeSheet = .rest
            }
            
            settingsRow(title: "Rondas", value: vm.config.roundsDisplay) {
                activeSheet = .rounds
            }
            
            settingsRow(title: "Enfriamiento", value: vm.config.cooldownDisplay) {
                activeSheet = .cooldown
            }
        } header: {
            Text("Ajustes del Temporizador")
                .font(.headline)
                .foregroundColor(.primary)
                .navigationBarTitleDisplayMode(.large)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarRole(.editor)
        } footer: {
            Text("Configura los intervalos para tu entrenamiento HIIT")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func settingsRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(value)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Toca para editar")
    }
        
    @ViewBuilder
    private func sheetView(for sheetType: ConfigSheetType) -> some View {
        switch sheetType {
        case .prep:
            TimeWheelSheet(title: "Preparación", maxSeconds: 59, totalSeconds: $vm.config.prepSeconds)
                .accentColor(.orange)
            
        case .work:
            TimeWheelSheet(title: "Entrenar", maxSeconds: 3599, totalSeconds: $vm.config.workSeconds)
                .accentColor(.green)
            
        case .rest:
            TimeWheelSheet(title: "Descansar", maxSeconds: 3599, totalSeconds: $vm.config.restSeconds)
                .accentColor(.blue)
            
        case .rounds:
            SingleWheelSheet(title: "Rondas", range: 1...20, value: $vm.config.rounds)
                .accentColor(.purple)
            
        case .cooldown:
            TimeWheelSheet(title: "Enfriamiento", maxSeconds: 3599, totalSeconds: $vm.config.cooldownSeconds)
                .accentColor(.indigo)
        }
    }
}

enum ConfigSheetType: Identifiable {
    case prep, work, rest, rounds, cooldown
    
    var id: Int {
        hashValue
    }
}

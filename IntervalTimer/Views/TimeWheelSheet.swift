/*
Propósito:
- Componente para selección de duraciones
- Divide la selección en minutos y segundos
- Configurar intervalos de entrenamiento

1. Doble wheel picker (minutos + segundos)
2. Validación automática de rango máximo
*/

import SwiftUI

struct TimeWheelSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let maxSeconds: Int
    @Binding var totalSeconds: Int
    
    @State private var minutes: Int
    @State private var seconds: Int
    
    init(title: String, maxSeconds: Int, totalSeconds: Binding<Int>) {
        self.title = title
        self.maxSeconds = maxSeconds
        _totalSeconds = totalSeconds
        
        let total = totalSeconds.wrappedValue
        _minutes = State(initialValue: total / 60)
        _seconds = State(initialValue: total % 60)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    
                    VStack {
                        Text("Min").font(.caption.bold())
                        Picker("", selection: $minutes) {
                            ForEach(0...59, id: \.self) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        .labelsHidden()
                    }
                    
                    VStack {
                        Text("Seg").font(.caption.bold())
                        Picker("", selection: $seconds) {
                            ForEach(0...59, id: \.self) { Text(String(format: "%02d",$0)).tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        .labelsHidden()
                    }
                }
                .frame(height: 180)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        totalSeconds = minutes * 60 + seconds
                        dismiss()
                    }
                }
            }
        }
    }
}

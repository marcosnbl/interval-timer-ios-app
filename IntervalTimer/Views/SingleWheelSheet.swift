/*
Propósito:
- Componente para selección de valores discretos
- Usado para parámetros como rondas o intervalos cortos
- Diseño optimizado para selección rápida

1. Interfaz tipo wheel picker nativa
2. Manejo de rangos personalizables
*/



import SwiftUI

struct SingleWheelSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let range: ClosedRange<Int>
    @Binding var value: Int
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker(title, selection: $value) {
                    let rangeValues = title == "Rondas" ? 0...30 : 0...59
                    ForEach(rangeValues, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 180)
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Guardar") { dismiss() } }
            }
        }
    }
}

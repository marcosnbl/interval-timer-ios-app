/*
 ConfigurationView.swift

 Propósito:
 - Pantalla de configuración del entrenamiento
 - Diseño limpio siguiendo Apple HIG
 - Pickers personalizados para tiempo y rondas

 Diseño: Lista agrupada con estilo iOS nativo
*/

import SwiftUI

struct ConfigurationView: View {
    @ObservedObject var timer: TimerManager
    @Environment(\.dismiss) private var dismiss

    @State private var showPrepPicker = false
    @State private var showWorkPicker = false
    @State private var showRestPicker = false
    @State private var showRoundsPicker = false
    @State private var showCooldownPicker = false

    var body: some View {
        List {
            // Sección de tiempos
            Section {
                configRow(
                    icon: "figure.stand",
                    iconColor: .yellow,
                    title: "Preparación",
                    value: timer.config.prepDisplay
                ) {
                    showPrepPicker = true
                }

                configRow(
                    icon: "flame.fill",
                    iconColor: .green,
                    title: "Trabajo",
                    value: timer.config.workDisplay
                ) {
                    showWorkPicker = true
                }

                configRow(
                    icon: "pause.circle.fill",
                    iconColor: .red,
                    title: "Descanso",
                    value: timer.config.restDisplay
                ) {
                    showRestPicker = true
                }
            } header: {
                Text("Intervalos")
            }

            // Sección de rondas
            Section {
                configRow(
                    icon: "repeat",
                    iconColor: .blue,
                    title: "Rondas",
                    value: timer.config.roundsDisplay
                ) {
                    showRoundsPicker = true
                }
            } header: {
                Text("Repeticiones")
            }

            // Sección de enfriamiento
            Section {
                configRow(
                    icon: "snowflake",
                    iconColor: .cyan,
                    title: "Enfriamiento",
                    value: timer.config.cooldownDisplay
                ) {
                    showCooldownPicker = true
                }
            } header: {
                Text("Recuperación")
            } footer: {
                Text("El enfriamiento es opcional. Configúralo a 0 para omitirlo.")
            }

            // Resumen del entrenamiento
            Section {
                totalWorkoutSummary
            } header: {
                Text("Resumen")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Configuración")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPrepPicker) {
            TimePicker(
                title: "Preparación",
                seconds: Binding(
                    get: { timer.config.prepSeconds },
                    set: { newValue in timer.updateConfig { $0.prepSeconds = newValue } }
                ),
                maxSeconds: 60
            )
        }
        .sheet(isPresented: $showWorkPicker) {
            TimePicker(
                title: "Trabajo",
                seconds: Binding(
                    get: { timer.config.workSeconds },
                    set: { newValue in timer.updateConfig { $0.workSeconds = newValue } }
                ),
                maxSeconds: 300
            )
        }
        .sheet(isPresented: $showRestPicker) {
            TimePicker(
                title: "Descanso",
                seconds: Binding(
                    get: { timer.config.restSeconds },
                    set: { newValue in timer.updateConfig { $0.restSeconds = newValue } }
                ),
                maxSeconds: 300
            )
        }
        .sheet(isPresented: $showRoundsPicker) {
            RoundsPicker(
                rounds: Binding(
                    get: { timer.config.rounds },
                    set: { newValue in timer.updateConfig { $0.rounds = newValue } }
                )
            )
        }
        .sheet(isPresented: $showCooldownPicker) {
            TimePicker(
                title: "Enfriamiento",
                seconds: Binding(
                    get: { timer.config.cooldownSeconds },
                    set: { newValue in timer.updateConfig { $0.cooldownSeconds = newValue } }
                ),
                maxSeconds: 300,
                allowZero: true
            )
        }
    }

    // MARK: - Config Row

    private func configRow(
        icon: String,
        iconColor: Color,
        title: String,
        value: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 32)

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                Text(value)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Workout Summary

    private var totalWorkoutSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
                Text("Duración total")
                    .fontWeight(.medium)
                Spacer()
                Text(totalWorkoutTime)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
            }

            Divider()

            // Desglose visual
            HStack(spacing: 4) {
                workoutSegment(color: .yellow, label: "Prep")
                ForEach(0..<timer.config.rounds, id: \.self) { round in
                    workoutSegment(color: .green, label: "")
                    if round < timer.config.rounds - 1 {
                        workoutSegment(color: .red, label: "")
                    }
                }
                if timer.config.cooldownSeconds > 0 {
                    workoutSegment(color: .cyan, label: "Cool")
                }
            }
            .frame(height: 24)
        }
        .padding(.vertical, 4)
    }

    private func workoutSegment(color: Color, label: String) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color.opacity(0.8))
            .overlay {
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
    }

    private var totalWorkoutTime: String {
        let config = timer.config
        let total = config.prepSeconds +
                    (config.workSeconds * config.rounds) +
                    (config.restSeconds * (config.rounds - 1)) +
                    config.cooldownSeconds

        let minutes = total / 60
        let seconds = total % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Time Picker

struct TimePicker: View {
    let title: String
    @Binding var seconds: Int
    let maxSeconds: Int
    var allowZero: Bool = false

    @Environment(\.dismiss) private var dismiss

    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Selecciona el tiempo")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)

                HStack(spacing: 0) {
                    // Minutos
                    Picker("Minutos", selection: $selectedMinutes) {
                        ForEach(0..<(maxSeconds / 60 + 1), id: \.self) { min in
                            Text("\(min)")
                                .tag(min)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)

                    Text("min")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    // Segundos
                    Picker("Segundos", selection: $selectedSeconds) {
                        ForEach(0..<60, id: \.self) { sec in
                            Text(String(format: "%02d", sec))
                                .tag(sec)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)

                    Text("seg")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 200)

                // Preview del tiempo
                Text(previewTime)
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                selectedMinutes = seconds / 60
                selectedSeconds = seconds % 60
            }
        }
        .presentationDetents([.medium])
    }

    private var previewTime: String {
        String(format: "%d:%02d", selectedMinutes, selectedSeconds)
    }

    private var totalSeconds: Int {
        selectedMinutes * 60 + selectedSeconds
    }

    private var isValid: Bool {
        if allowZero {
            return totalSeconds <= maxSeconds
        }
        return totalSeconds > 0 && totalSeconds <= maxSeconds
    }

    private func saveAndDismiss() {
        seconds = totalSeconds
        dismiss()
    }
}

// MARK: - Rounds Picker

struct RoundsPicker: View {
    @Binding var rounds: Int
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRounds: Int = 8

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Número de rondas")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)

                Picker("Rondas", selection: $selectedRounds) {
                    ForEach(1...30, id: \.self) { num in
                        Text("\(num)")
                            .tag(num)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 200)

                // Visualización de rondas
                HStack(spacing: 6) {
                    ForEach(0..<min(selectedRounds, 15), id: \.self) { _ in
                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                    }
                    if selectedRounds > 15 {
                        Text("+\(selectedRounds - 15)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("\(selectedRounds) rondas de trabajo")
                    .font(.title2)
                    .fontWeight(.medium)

                Spacer()
            }
            .navigationTitle("Rondas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        rounds = selectedRounds
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedRounds = rounds
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConfigurationView(timer: TimerManager())
    }
}

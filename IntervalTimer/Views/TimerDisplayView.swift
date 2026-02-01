/*
 TimerDisplayView.swift

 Propósito:
 - Vista principal del temporizador con diseño Bold
 - Números gigantes de alto contraste
 - Animaciones fluidas de transición
 - Indicador de progreso circular

 Diseño: Apple Human Interface Guidelines
 - Tipografía clara y legible
 - Colores vibrantes por estado
 - Feedback visual inmediato
*/

import SwiftUI

struct TimerDisplayView: View {
    @ObservedObject var timer: TimerManager

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient animado
                backgroundGradient
                    .animation(.easeInOut(duration: 0.5), value: timer.phase)

                VStack(spacing: 0) {
                    // Header con navegación
                    headerView
                        .padding(.top, 8)

                    Spacer()

                    // Contenido principal
                    mainContent(geometry: geometry)

                    Spacer()

                    // Controles
                    controlButtons
                        .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: timer.phase.gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            // Patrón sutil para profundidad
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .offset(y: -100)
                .blur(radius: 60)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Spacer()
            NavigationLink {
                ConfigurationView(timer: timer)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(12)
                    .background(.ultraThinMaterial.opacity(0.3))
                    .clipShape(Circle())
            }
            .accessibilityIdentifier("SettingsButton")
            .disabled(timer.isRunning)
            .opacity(timer.isRunning ? 0.5 : 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }

    // MARK: - Main Content

    private func mainContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            // Fase actual
            phaseLabel

            // Timer circular con números gigantes
            timerDisplay(size: min(geometry.size.width * 0.85, 380))

            // Indicador de ronda
            roundIndicator
        }
    }

    private var phaseLabel: some View {
        Text(timer.phase.displayName)
            .font(.system(size: 28, weight: .black, design: .rounded))
            .tracking(4)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.3), value: timer.phase)
    }

    private func timerDisplay(size: CGFloat) -> some View {
        ZStack {
            // Círculo de fondo
            Circle()
                .stroke(lineWidth: 12)
                .foregroundStyle(.white.opacity(0.2))

            // Círculo de progreso
            Circle()
                .trim(from: 0, to: 1 - timer.progress)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 12,
                        lineCap: .round
                    )
                )
                .foregroundStyle(.white)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: timer.progress)

            // Tiempo gigante
            VStack(spacing: 4) {
                Text(timer.formattedTime)
                    .font(.system(size: size * 0.32, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.easeInOut(duration: 0.15), value: timer.remainingSeconds)

                // Segundos restantes pequeños (para precisión visual)
                if timer.remainingSeconds <= 5 && timer.remainingSeconds > 0 && timer.isRunning {
                    Text("\(timer.remainingSeconds)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(width: size, height: size)
        .padding(.vertical, 20)
    }

    private var roundIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...timer.totalRounds, id: \.self) { round in
                RoundDot(
                    isCompleted: round < timer.currentRound,
                    isCurrent: round == timer.currentRound,
                    isActive: timer.phase == .work && round == timer.currentRound
                )
            }
        }
        .padding(.horizontal, 20)
        .opacity(timer.phase == .done ? 0.5 : 1)
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 24) {
            if timer.state != .idle && timer.state != .finished {
                // Botón Reset
                Button {
                    timer.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.ultraThinMaterial.opacity(0.3))
                        .clipShape(Circle())
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Botón Principal
            Button {
                timer.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                    Image(systemName: mainButtonIcon)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(timer.phase.color)
                }
            }
            .accessibilityIdentifier("MainActionButton")

            if timer.state != .idle && timer.state != .finished {
                // Spacer para balance visual
                Color.clear
                    .frame(width: 60, height: 60)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: timer.state)
    }

    private var mainButtonIcon: String {
        switch timer.state {
        case .idle:
            return "play.fill"
        case .running:
            return "pause.fill"
        case .paused:
            return "play.fill"
        case .finished:
            return "arrow.counterclockwise"
        }
    }
}

// MARK: - Round Dot Component

struct RoundDot: View {
    let isCompleted: Bool
    let isCurrent: Bool
    let isActive: Bool

    var body: some View {
        Circle()
            .fill(dotColor)
            .frame(width: dotSize, height: dotSize)
            .overlay {
                if isCurrent && isActive {
                    Circle()
                        .stroke(.white, lineWidth: 2)
                        .scaleEffect(1.5)
                        .opacity(0.5)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isCompleted)
            .animation(.easeInOut(duration: 0.3), value: isCurrent)
    }

    private var dotColor: Color {
        if isCompleted {
            return .white
        } else if isCurrent {
            return .white.opacity(0.9)
        } else {
            return .white.opacity(0.3)
        }
    }

    private var dotSize: CGFloat {
        isCurrent ? 12 : 8
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TimerDisplayView(timer: TimerManager())
    }
}

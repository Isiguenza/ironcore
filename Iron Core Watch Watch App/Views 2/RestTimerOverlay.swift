import SwiftUI

struct RestTimerOverlay: View {
    @StateObject private var workoutManager = WatchWorkoutManager.shared
    private let maxRestTime: CGFloat = 180

    var body: some View {
        VStack(spacing: 0) {

            // Zona superior: NEXT (adaptativa)
            nextExerciseArea
                .padding(.top, 35)
                
                

            

            // Timer centrado
            Text(formatTime(workoutManager.restTimeRemaining))
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .layoutPriority(2)
                .padding()

            // Empuja botones hacia abajo
            Spacer(minLength: 0)

            // Botones abajo (sin height fijo)
            HStack(spacing: 12) {
                restAdjustButton(title: "-15s") { adjustRestTime(by: -15) }
                restAdjustButton(title: "+15s") { adjustRestTime(by: 15) }
            }
            .padding(.bottom, 6)
            .layoutPriority(1)
            .padding(.bottom)
           
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(borderProgressOverlay) // 👈 tu overlay igual
        .ignoresSafeArea()
    }

    // MARK: - NEXT adaptativo (automático)

    private var nextExerciseArea: some View {
        // Esta zona se adapta: si no cabe el layout grande, cae al compacto.
        ViewThatFits(in: .vertical) {
            nextExerciseBlockLarge
            nextExerciseBlockCompact
            Color.clear.frame(height: 1) // último recurso
        }
        // “pide” menos espacio cuando el watch está apretado
        .layoutPriority(0)
    }

    private var nextExerciseBlockLarge: some View {
        Group {
            if let workout = workoutManager.activeWorkout,
               let currentExercise = workout.exercises.first(where: { $0.completedSets.count < $0.targetSets }) {

                VStack(spacing: 6) {
                    Text("NEXT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1.5)

                    Text(currentExercise.exercise.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    if let weight = currentExercise.targetWeight,
                       let reps = currentExercise.targetReps {

                        HStack(spacing: 10) {
                            HStack(spacing: 3) {
                                Image(systemName: "scalemass")
                                    .font(.system(size: 9))
                                Text("\(String(format: "%.0f", weight))")
                                    .font(.system(size: 13, weight: .semibold))
                            }

                            Text("×")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)

                            HStack(spacing: 3) {
                                Image(systemName: "repeat")
                                    .font(.system(size: 9))
                                Text("\(reps)")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 10)

            } else {
                // Si no hay next, ocupa poco (sin afectar layout)
                Color.clear.frame(height: 40)
            }
        }
    }

    private var nextExerciseBlockCompact: some View {
        Group {
            if let workout = workoutManager.activeWorkout,
               let currentExercise = workout.exercises.first(where: { $0.completedSets.count < $0.targetSets }) {

                VStack(spacing: 4) {
                    Text("NEXT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1.5)

                    Text(currentExercise.exercise.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .padding(.horizontal, 10)
            } else {
                Color.clear.frame(height: 24)
            }
        }
    }

    // MARK: - Tu overlay (igual, no movido)

    private var borderProgressOverlay: some View {
        GeometryReader { proxy in
            ZStack {
                let progress = max(0, min(1, CGFloat(workoutManager.restTimeRemaining) / maxRestTime))
                let lineWidth: CGFloat = 3.5
                let inset = lineWidth / 2
                let cornerRadius: CGFloat = 42

                let size = proxy.size
                let w = max(0, size.width - (inset * 2))
                let h = max(0, size.height - (inset * 2))
                let r = min(cornerRadius, min(w, h) / 2)

                let straight = 2 * ((w - 2*r) + (h - 2*r))
                let arcs = 2 * .pi * r
                let perimeter = max(1, straight + arcs)

                let dCCW =
                    max(0, (h / 2 - r)) +
                    (.pi * r / 2) +
                    max(0, (w / 2 - r))

                let start = 1 - (dCCW / perimeter)
                let end = start + progress

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .inset(by: inset)
                    .stroke(Color.white.opacity(0.12), lineWidth: lineWidth)

                if end <= 1 {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .inset(by: inset)
                        .trim(from: start, to: end)
                        .stroke(
                            LinearGradient(
                                colors: [Color.neonGreen, Color.neonGreen.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                        )
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .inset(by: inset)
                        .trim(from: start, to: 1)
                        .stroke(
                            LinearGradient(
                                colors: [Color.neonGreen, Color.neonGreen.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                        )

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .inset(by: inset)
                        .trim(from: 0, to: end - 1)
                        .stroke(
                            LinearGradient(
                                colors: [Color.neonGreen, Color.neonGreen.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                        )
                }
            }
            .padding(4)
            .animation(.linear(duration: 0.15), value: workoutManager.restTimeRemaining)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func adjustRestTime(by seconds: Int) {
        let newTime = max(0, workoutManager.restTimeRemaining + seconds)
        workoutManager.restTimeRemaining = newTime
    }

    // MARK: - Buttons (tu estilo)

    private func restAdjustButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.neonGreen)
                .frame(maxWidth: 60)
        }
        .buttonStyle(.plain)
        .background(
            Capsule()
                .fill(Color.neonGreen.opacity(0.20))
                .frame(height: 40)
        )
        .overlay(
            Capsule()
                .stroke(Color.neonGreen.opacity(0.25), lineWidth: 1)
                .frame(height: 40)
        )
    }
}

#Preview {
    RestTimerOverlay()
}

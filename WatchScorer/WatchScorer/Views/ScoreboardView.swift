import SwiftUI

struct ScoreboardView: View {
    let myScore: Int
    let opponentScore: Int
    let isWorkoutActive: Bool
    let toggleWorkout: () -> Void
    let primaryIncrement: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Snap 計分")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(alignment: .center) {
                VStack {
                    Text("我方")
                        .font(.caption2)
                    Text("\(myScore)")
                        .font(.system(size: 44, weight: .bold))
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)

                Button(action: primaryIncrement) {
                    VStack(spacing: 4) {
                        Text("+1")
                            .font(.title2)
                        Text("主手勢")
                            .font(.caption2)
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("我方加一分")
                .accessibilityHint("單次腕部微動")

                VStack {
                    Text("對手")
                        .font(.caption2)
                    Text("\(opponentScore)")
                        .font(.system(size: 44, weight: .bold))
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)
            }

            Button(action: toggleWorkout) {
                Label(isWorkoutActive ? "結束比賽" : "開始比賽",
                      systemImage: isWorkoutActive ? "stop.circle" : "play.circle")
            }
            .buttonStyle(.bordered)
            .tint(isWorkoutActive ? .red : .green)
        }
    }
}

#Preview {
    ScoreboardView(myScore: 3,
                   opponentScore: 2,
                   isWorkoutActive: true,
                   toggleWorkout: {},
                   primaryIncrement: {})
}

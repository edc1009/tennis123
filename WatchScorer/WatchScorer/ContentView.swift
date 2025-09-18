import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showingSettings = false
    @State private var showingCalibration = false

    var body: some View {
        VStack(spacing: 16) {
            ScoreboardView(myScore: viewModel.playerScore,
                           opponentScore: viewModel.opponentScore,
                           isWorkoutActive: viewModel.isWorkoutActive,
                           toggleWorkout: viewModel.toggleWorkoutSession,
                           primaryIncrement: viewModel.incrementPlayer)
                .padding(.horizontal, 12)

            HStack {
                Button(action: viewModel.incrementOpponent) {
                    VStack {
                        Text("對手 +1")
                            .font(.headline)
                        Text("雙次手勢")
                            .font(.footnote)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button(action: viewModel.undoLastAction) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canUndo)
            }

            HStack {
                Button("設定") { showingSettings = true }
                Button("校準") { showingCalibration = true }
            }
            .font(.footnote)
        }
        .padding()
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: viewModel.settings,
                         applyAction: viewModel.updateSettings,
                         dismiss: { showingSettings = false })
        }
        .sheet(isPresented: $showingCalibration) {
            CalibrationView(calibrationState: viewModel.calibrationState,
                            startAction: viewModel.startCalibration,
                            finishAction: viewModel.finishCalibration,
                            dismiss: { showingCalibration = false })
        }
        .onAppear { viewModel.onAppear() }
        .primaryAction(viewModel.incrementPlayer)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel(isPreview: true))
}

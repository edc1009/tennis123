import Combine
import CoreMotion
import Foundation
import HealthKit
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var playerScore = 0
    @Published private(set) var opponentScore = 0
    @Published private(set) var canUndo = false
    @Published private(set) var isWorkoutActive = false
    @Published private(set) var calibrationState = CalibrationState.idle
    @Published private(set) var settings: AppSettings

    private let motionStream: MotionStream
    private let gestureEngine: GestureEngine
    private let haptics = HapticsManager()
    private let workoutManager = WorkoutSessionManager()
    private let persistence = PersistenceController()
    private let scoringService = ScoringService()

    private var cancellables: Set<AnyCancellable> = []
    private var calibrationSamples: [GestureCalibrationSample] = []
    private var calibrationStreaming = false

    init(isPreview: Bool = false) {
        let storedSettings = persistence.loadSettings() ?? .default
        settings = storedSettings
        motionStream = MotionStream(sampleRate: storedSettings.gesture.sampleRate, isPreview: isPreview)
        gestureEngine = GestureEngine(configuration: storedSettings.gesture)
        gestureEngine.updateDominantWrist(storedSettings.profile.dominantWrist)

        if isPreview {
            scoringService.applyPreviewScores()
        }

        refreshScores()

        bindStreams()
    }

    func onAppear() {
        Task {
            await workoutManager.requestAuthorizationIfNeeded()
        }
    }

    func incrementPlayer() {
        scoringService.record(.player)
        refreshScores()
        haptics.play(.single)
    }

    func incrementOpponent() {
        scoringService.record(.opponent)
        refreshScores()
        haptics.play(.double)
    }

    func undoLastAction() {
        scoringService.undo()
        refreshScores()
    }

    func toggleWorkoutSession() {
        Task {
            if isWorkoutActive {
                await workoutManager.stopWorkout()
                stopMotion()
            } else {
                do {
                    try await workoutManager.startWorkout(storeToHealthKit: settings.profile.storeToHealthKit)
                    startMotion()
                } catch {
                    print("Failed to start workout: \(error)")
                }
            }
        }
    }

    func updateSettings(_ settings: AppSettings) {
        self.settings = settings
        gestureEngine.updateConfiguration(settings.gesture)
        gestureEngine.updateDominantWrist(settings.profile.dominantWrist)
        motionStream.update(sampleRate: settings.gesture.sampleRate)
        persistence.save(settings: settings)
    }

    func startCalibration() {
        calibrationSamples = []
        calibrationState = .recording
        gestureEngine.pauseDetection(true)
        if !motionStream.isRunning {
            motionStream.start()
            calibrationStreaming = true
        }
    }

    func finishCalibration() {
        defer {
            if calibrationStreaming && !isWorkoutActive {
                motionStream.stop()
            }
            calibrationStreaming = false
        }

        guard calibrationState == .recording else {
            calibrationState = .idle
            gestureEngine.pauseDetection(false)
            return
        }

        let analyzer = CalibrationAnalyzer()
        let result = analyzer.deriveSettings(from: calibrationSamples)
        var updatedSettings = settings
        if let single = result.singleThreshold {
            updatedSettings.gesture.singleSnapThreshold = single
        }
        if let variance = result.variance {
            updatedSettings.gesture.lowActivityVariance = variance
        }
        settings = updatedSettings
        gestureEngine.updateConfiguration(updatedSettings.gesture)
        persistence.save(settings: updatedSettings)
        calibrationState = .completed
        gestureEngine.pauseDetection(false)
    }

    private func startMotion() {
        guard !isWorkoutActive else { return }
        isWorkoutActive = true
        motionStream.start()
    }

    private func stopMotion() {
        guard isWorkoutActive else { return }
        isWorkoutActive = false
        motionStream.stop()
        persistence.persistScoresIfNeeded(scoringService, enabled: settings.profile.persistLocally)
    }

    private func bindStreams() {
        motionStream.motionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sample in
                guard let self else { return }
                if calibrationState == .recording {
                    calibrationSamples.append(GestureCalibrationSample(timestamp: sample.timestamp,
                                                                       rotationRate: sample.rotationRate,
                                                                       userAccelerationMagnitude: sample.userAccelerationMagnitude))
                }
                gestureEngine.process(sample)
            }
            .store(in: &cancellables)

        gestureEngine.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .player:
                    scoringService.record(.player)
                    refreshScores()
                    haptics.play(.single)
                case .opponent:
                    scoringService.record(.opponent)
                    refreshScores()
                    haptics.play(.double)
                }
            }
            .store(in: &cancellables)

        workoutManager.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                if state == .ended {
                    stopMotion()
                }
            }
            .store(in: &cancellables)
    }

    private func refreshScores() {
        playerScore = scoringService.playerScore
        opponentScore = scoringService.opponentScore
        canUndo = scoringService.canUndo
    }
}

// MARK: - Calibration support

struct GestureCalibrationSample {
    let timestamp: TimeInterval
    let rotationRate: Double
    let userAccelerationMagnitude: Double
}

enum CalibrationState {
    case idle
    case recording
    case completed
}

struct CalibrationResult {
    let singleThreshold: Double?
    let variance: Double?
}

struct CalibrationAnalyzer {
    func deriveSettings(from samples: [GestureCalibrationSample]) -> CalibrationResult {
        guard !samples.isEmpty else { return CalibrationResult(singleThreshold: nil, variance: nil) }

        let magnitudes = samples.map { abs($0.rotationRate) }
        let sorted = magnitudes.sorted()
        let percentileIndex = max(Int(Double(sorted.count) * 0.7) - 1, 0)
        let threshold = sorted[percentileIndex]

        let rotationMean = samples.reduce(0) { $0 + $1.rotationRate } / Double(samples.count)
        let variance = samples.reduce(0) { $0 + pow($1.rotationRate - rotationMean, 2) } / Double(samples.count)

        return CalibrationResult(singleThreshold: threshold, variance: variance)
    }
}

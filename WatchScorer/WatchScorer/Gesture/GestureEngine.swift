import Combine
import Foundation

enum GestureEvent {
    case player
    case opponent
}

final class GestureEngine {
    private var configuration: GestureSettings
    private var rotationWindow: [(time: TimeInterval, value: Double)] = []
    private var lastTriggerTime: TimeInterval?
    private var pendingSingleTime: TimeInterval?
    private var isPaused = false
    private var orientationMultiplier: Double = 1

    let eventPublisher = PassthroughSubject<GestureEvent, Never>()

    init(configuration: GestureSettings) {
        self.configuration = configuration
    }

    func updateConfiguration(_ configuration: GestureSettings) {
        self.configuration = configuration
        rotationWindow.removeAll(keepingCapacity: true)
        pendingSingleTime = nil
        lastTriggerTime = nil
    }

    func updateDominantWrist(_ wrist: DominantWrist) {
        orientationMultiplier = wrist == .left ? -1 : 1
    }

    func pauseDetection(_ pause: Bool) {
        isPaused = pause
        if pause {
            pendingSingleTime = nil
        }
    }

    func process(_ sample: MotionSample) {
        guard !isPaused else { return }

        let adjustedRotation = sample.rotationRate * orientationMultiplier
        rotationWindow.append((time: sample.timestamp, value: adjustedRotation))
        trimWindow(before: sample.timestamp - configuration.lowActivityWindow)

        let isLowActivity = computeVariance() < configuration.lowActivityVariance
        let magnitude = abs(adjustedRotation)

        if let pending = pendingSingleTime,
           sample.timestamp - pending >= configuration.doubleMaxInterval {
            pendingSingleTime = nil
            eventPublisher.send(.player)
            lastTriggerTime = sample.timestamp
        }

        guard isLowActivity else { return }
        guard magnitude >= configuration.singleSnapThreshold else { return }

        if let last = lastTriggerTime, sample.timestamp - last < configuration.refractoryPeriod {
            return
        }

        if let pending = pendingSingleTime,
           sample.timestamp - pending >= configuration.doubleMinInterval,
           sample.timestamp - pending <= configuration.doubleMaxInterval {
            pendingSingleTime = nil
            lastTriggerTime = sample.timestamp
            eventPublisher.send(.opponent)
        } else {
            pendingSingleTime = sample.timestamp
        }
    }

    private func trimWindow(before cutoff: TimeInterval) {
        while let first = rotationWindow.first, first.time < cutoff {
            rotationWindow.removeFirst()
        }
    }

    private func computeVariance() -> Double {
        guard !rotationWindow.isEmpty else { return .greatestFiniteMagnitude }
        let mean = rotationWindow.reduce(0) { $0 + $1.value } / Double(rotationWindow.count)
        let variance = rotationWindow.reduce(0) { $0 + pow($1.value - mean, 2) } / Double(rotationWindow.count)
        return variance
    }
}

import Combine
import CoreMotion
import Foundation

struct MotionSample {
    let timestamp: TimeInterval
    let rotationRate: Double
    let userAccelerationMagnitude: Double
}

final class MotionStream {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private(set) var sampleRate: Double
    private let isPreview: Bool
    private(set) var isRunning = false

    let motionPublisher = PassthroughSubject<MotionSample, Never>()

    init(sampleRate: Double, isPreview: Bool) {
        self.sampleRate = sampleRate
        self.isPreview = isPreview
        queue.qualityOfService = .userInteractive
    }

    func start() {
        guard !isPreview else { return }
        guard !isRunning else { return }
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / sampleRate
        motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: queue) { [weak self] motion, _ in
            guard let motion = motion else { return }
            let sample = MotionSample(timestamp: motion.timestamp,
                                      rotationRate: motion.rotationRate.x,
                                      userAccelerationMagnitude: motion.userAcceleration.magnitude)
            self?.motionPublisher.send(sample)
        }
        isRunning = true
    }

    func stop() {
        guard !isPreview else { return }
        motionManager.stopDeviceMotionUpdates()
        isRunning = false
    }

    func update(sampleRate: Double) {
        self.sampleRate = sampleRate
        if motionManager.isDeviceMotionActive {
            stop()
            start()
        }
    }
}

private extension CMAcceleration {
    var magnitude: Double {
        sqrt(x * x + y * y + z * z)
    }
}

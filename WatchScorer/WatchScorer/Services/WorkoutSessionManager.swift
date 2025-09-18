import Combine
import HealthKit

enum WorkoutSessionState {
    case notStarted
    case running
    case ended
}

final class WorkoutSessionManager: NSObject {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var shouldStoreToHealthKit = false

    private let stateSubject = CurrentValueSubject<WorkoutSessionState, Never>(.notStarted)
    var statePublisher: AnyPublisher<WorkoutSessionState, Never> { stateSubject.eraseToAnyPublisher() }

    func requestAuthorizationIfNeeded() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let readTypes: Set = [] as Set<HKObjectType>
        let shareTypes: Set = [HKObjectType.workoutType()]
        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }

    func startWorkout(storeToHealthKit: Bool) async throws {
        guard session == nil else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .otherCombat
        configuration.locationType = .indoor

        session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        builder = session?.associatedWorkoutBuilder()
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

        session?.delegate = self
        builder?.delegate = self

        session?.startActivity(with: Date())
        shouldStoreToHealthKit = storeToHealthKit
        if shouldStoreToHealthKit {
            builder?.beginCollection(withStart: Date()) { _, _ in }
        }
        stateSubject.send(.running)
    }

    func stopWorkout() async {
        guard let session else { return }
        session.end()
        guard shouldStoreToHealthKit else {
            stateSubject.send(.ended)
            self.session = nil
            self.builder = nil
            self.shouldStoreToHealthKit = false
            return
        }

        builder?.endCollection(withEnd: Date()) { [weak self] _, _ in
            guard let self else { return }
            self.builder?.finishWorkout { _, _ in }
            self.stateSubject.send(.ended)
            self.session = nil
            self.builder = nil
            self.shouldStoreToHealthKit = false
        }
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        if toState == .ended {
            stateSubject.send(.ended)
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout failed: \(error)")
        stateSubject.send(.ended)
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollect dataSources: Set<HKLiveWorkoutDataSource>) {}
}

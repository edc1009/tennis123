import Foundation

struct AppSettings: Codable, Equatable {
    var gesture: GestureSettings
    var profile: ProfileSettings

    static let `default` = AppSettings(gesture: .default, profile: .default)
}

struct GestureSettings: Codable, Equatable {
    var singleSnapThreshold: Double
    var lowActivityVariance: Double
    var lowActivityWindow: TimeInterval
    var doubleMinInterval: TimeInterval
    var doubleMaxInterval: TimeInterval
    var refractoryPeriod: TimeInterval
    var sampleRate: Double

    static let `default` = GestureSettings(singleSnapThreshold: 5.5,
                                           lowActivityVariance: 0.15,
                                           lowActivityWindow: 0.4,
                                           doubleMinInterval: 0.6,
                                           doubleMaxInterval: 0.9,
                                           refractoryPeriod: 1.2,
                                           sampleRate: 50)
}

struct ProfileSettings: Codable, Equatable {
    var dominantWrist: DominantWrist
    var storeToHealthKit: Bool
    var persistLocally: Bool

    static let `default` = ProfileSettings(dominantWrist: .right,
                                           storeToHealthKit: true,
                                           persistLocally: true)
}

enum DominantWrist: String, Codable, CaseIterable {
    case left
    case right

    var label: String {
        switch self {
        case .left: return "左手"
        case .right: return "右手"
        }
    }
}

import Foundation

final class PersistenceController {
    private let settingsURL: URL
    private let scoreLogURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.snapscorer") ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        settingsURL = container.appendingPathComponent("settings.json")
        scoreLogURL = container.appendingPathComponent("scores.csv")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func save(settings: AppSettings) {
        do {
            let data = try encoder.encode(settings)
            try data.write(to: settingsURL, options: .atomic)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }

    func loadSettings() -> AppSettings? {
        do {
            let data = try Data(contentsOf: settingsURL)
            return try decoder.decode(AppSettings.self, from: data)
        } catch {
            return nil
        }
    }

    func persistScoresIfNeeded(_ scoring: ScoringService, enabled: Bool) {
        guard enabled else { return }
        let snapshot = "\(Date().iso8601String),\(scoring.playerScore),\(scoring.opponentScore)\n"
        do {
            if FileManager.default.fileExists(atPath: scoreLogURL.path) {
                let handle = try FileHandle(forWritingTo: scoreLogURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                if let data = snapshot.data(using: .utf8) {
                    try handle.write(contentsOf: data)
                }
            } else {
                try snapshot.data(using: .utf8)?.write(to: scoreLogURL, options: .atomic)
            }
        } catch {
            print("Failed to persist scores: \(error)")
        }
    }
}

private extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}

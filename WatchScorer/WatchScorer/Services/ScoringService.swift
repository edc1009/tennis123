import Foundation

enum ScoreEvent: String, Codable {
    case player
    case opponent
}

struct ScoreSnapshot: Codable {
    let timestamp: Date
    let playerScore: Int
    let opponentScore: Int
}

final class ScoringService: Codable {
    private(set) var playerScore: Int = 0
    private(set) var opponentScore: Int = 0

    private var history: [ScoreEvent] = []

    var canUndo: Bool {
        !history.isEmpty
    }

    enum CodingKeys: CodingKey {
        case playerScore
        case opponentScore
        case history
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playerScore = try container.decode(Int.self, forKey: .playerScore)
        opponentScore = try container.decode(Int.self, forKey: .opponentScore)
        history = try container.decode([ScoreEvent].self, forKey: .history)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(playerScore, forKey: .playerScore)
        try container.encode(opponentScore, forKey: .opponentScore)
        try container.encode(history, forKey: .history)
    }

    func record(_ event: ScoreEvent) {
        switch event {
        case .player:
            playerScore += 1
        case .opponent:
            opponentScore += 1
        }
        history.append(event)
    }

    func undo() {
        guard let last = history.popLast() else { return }
        switch last {
        case .player:
            playerScore = max(playerScore - 1, 0)
        case .opponent:
            opponentScore = max(opponentScore - 1, 0)
        }
    }

    func reset() {
        playerScore = 0
        opponentScore = 0
        history.removeAll()
    }

    func applyPreviewScores() {
        playerScore = 4
        opponentScore = 3
        history = Array(repeating: .player, count: 4) + Array(repeating: .opponent, count: 3)
    }
}

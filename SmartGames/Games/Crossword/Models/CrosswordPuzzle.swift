import Foundation

enum ClueDirection: String, Codable { case across, down }

enum CrosswordDifficulty: String, Codable, CaseIterable, Identifiable {
    case mini, standard, easy, medium, hard
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .mini: return "Mini (5×5)"
        case .standard: return "Standard (9×9)"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
    var freeHints: Int {
        switch self {
        case .mini, .easy: return 5
        case .standard, .medium: return 3
        case .hard: return 1
        }
    }
    var gridSize: Int {
        switch self {
        case .mini, .easy: return 5
        case .standard, .medium, .hard: return 9
        }
    }
}

struct CrosswordSoftHints: Codable {
    let startsWith: String
    let length: Int
    let category: String
}

struct CrosswordClue: Codable, Identifiable {
    var id: String { "\(number)\(direction.rawValue.prefix(1).uppercased())" }
    let number: Int
    let direction: ClueDirection
    let text: String
    let startRow: Int
    let startCol: Int
    let length: Int
    var softHints: CrosswordSoftHints?
}

struct CrosswordPuzzleStats: Codable {
    let placedWordCount: Int
    let intersectionCount: Int
    let fillRatio: Double
    let generatorScore: Double
}

struct CrosswordPuzzle: Codable, Identifiable {
    let id: String
    let difficulty: CrosswordDifficulty
    let size: Int
    /// "#" = black cell, letter = solution char
    let grid: [[String]]
    let clues: [CrosswordClue]
    var freeHints: Int { difficulty.freeHints }
    // Optional pack-based fields (backward-compatible)
    var theme: String?
    var packId: String?
    var boardSize: String?
    var stats: CrosswordPuzzleStats?
}

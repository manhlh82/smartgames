import Foundation

struct CrosswordPackMeta: Codable, Identifiable {
    let packId: String
    let title: String
    let theme: String
    let difficulty: String
    let boardSize: String
    let puzzleCount: Int
    let resourceFile: String
    let isUnlocked: Bool
    let createdAt: String
    let version: String
    var id: String { packId }
}

struct CrosswordPacksIndex: Codable {
    let version: String
    let packs: [CrosswordPackMeta]
}

// MARK: - Pack-native puzzle model (maps JSON from pipeline output)

/// Entry as stored in pack JSON (uses pipeline field names).
struct CrosswordPackEntry: Codable {
    let number: Int
    let answer: String
    let direction: ClueDirection
    let row: Int
    let col: Int
    let length: Int
    let clue: String
    var softHints: CrosswordSoftHints?
    var theme: String?
    var difficulty: String?

    /// Convert to the canonical CrosswordClue used by the game engine.
    func toCrosswordClue() -> CrosswordClue {
        CrosswordClue(
            number: number,
            direction: direction,
            text: clue,
            startRow: row,
            startCol: col,
            length: length,
            softHints: softHints
        )
    }
}

/// Puzzle as stored in pack JSON (uses pipeline field names).
struct CrosswordPackPuzzle: Codable {
    let puzzleId: String
    let seed: Int?
    let theme: String?
    let difficulty: String?
    let rows: Int
    let cols: Int
    let solutionGrid: [[String]]
    let playerGrid: [[String?]]
    let entries: [CrosswordPackEntry]
    let uiMetadata: CrosswordPackUIMetadata?
    let stats: CrosswordPackStats?

    private enum CodingKeys: String, CodingKey {
        case puzzleId, seed, theme, difficulty, rows, cols
        case solutionGrid, playerGrid, entries, uiMetadata, stats
    }

    /// Convert to the canonical CrosswordPuzzle used by the game engine.
    func toCrosswordPuzzle(packId: String) -> CrosswordPuzzle {
        let diff = resolveDifficulty()
        return CrosswordPuzzle(
            id: puzzleId,
            difficulty: diff,
            size: rows,
            grid: solutionGrid,
            clues: entries.map { $0.toCrosswordClue() },
            theme: theme,
            packId: packId,
            boardSize: uiMetadata?.boardSize,
            stats: stats?.toCrosswordPuzzleStats()
        )
    }

    private func resolveDifficulty() -> CrosswordDifficulty {
        let raw = difficulty ?? uiMetadata?.difficulty ?? ""
        switch raw {
        case "easy": return .easy
        case "medium": return .medium
        case "hard": return .hard
        default: return rows <= 5 ? .mini : .standard
        }
    }
}

struct CrosswordPackUIMetadata: Codable {
    let boardSize: String?
    let theme: String?
    let difficulty: String?
}

struct CrosswordPackStats: Codable {
    let wordCount: Int?
    let intersections: Int?
    let boardScore: Double?

    func toCrosswordPuzzleStats() -> CrosswordPuzzleStats {
        CrosswordPuzzleStats(
            placedWordCount: wordCount ?? 0,
            intersectionCount: intersections ?? 0,
            fillRatio: boardScore ?? 0,
            generatorScore: boardScore ?? 0
        )
    }
}

/// Top-level structure of a pack JSON file.
struct CrosswordPack: Codable {
    let packId: String
    let title: String
    let theme: String
    let difficulty: String
    let boardSize: String
    let puzzles: [CrosswordPackPuzzle]

    /// Convert all puzzles to canonical CrosswordPuzzle array.
    func toCrosswordPuzzles() -> [CrosswordPuzzle] {
        puzzles.map { $0.toCrosswordPuzzle(packId: packId) }
    }
}

import Foundation

/// Loads crossword puzzles from bundled JSON, tracks played IDs to avoid repeats.
/// Supports both legacy crossword-puzzles.json and pack-based loading.
final class CrosswordPuzzleBank {
    private let persistence: PersistenceService
    private var puzzlesByDifficulty: [CrosswordDifficulty: [CrosswordPuzzle]] = [:]

    // Pack-based loading
    private var packsIndex: CrosswordPacksIndex?
    private var loadedPacks: [String: CrosswordPack] = [:]

    init(persistence: PersistenceService) {
        self.persistence = persistence
        loadPackIndex()
        loadBundledPuzzles()
    }

    /// Returns an unplayed puzzle for the given difficulty, cycling when exhausted.
    func getPuzzle(for difficulty: CrosswordDifficulty) -> CrosswordPuzzle? {
        let pool = puzzlesByDifficulty[difficulty] ?? []
        guard !pool.isEmpty else { return nil }
        let played = loadPlayedIDs()
        let available = pool.filter { !played.contains($0.id) }
        let puzzle = available.randomElement() ?? pool.randomElement()
        if let p = puzzle { markAsPlayed(puzzleID: p.id) }
        return puzzle
    }

    /// All puzzles for a given difficulty (used by daily challenge seeded selection).
    func allPuzzles(for difficulty: CrosswordDifficulty) -> [CrosswordPuzzle] {
        puzzlesByDifficulty[difficulty] ?? []
    }

    // MARK: - Pack API

    /// Load and cache a pack by its packId. Returns nil if not found in bundle.
    func getPack(id: String) -> CrosswordPack? {
        if let cached = loadedPacks[id] { return cached }
        let fileName = "crossword-pack-\(id)"
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let pack = try? JSONDecoder().decode(CrosswordPack.self, from: data) else {
            return nil
        }
        loadedPacks[id] = pack
        return pack
    }

    /// Metadata for all packs from the index (empty if no index loaded).
    func allPackMeta() -> [CrosswordPackMeta] {
        packsIndex?.packs ?? []
    }

    // MARK: - Private

    /// Try loading crossword-packs-index.json from bundle; sets packsIndex if found.
    func loadPackIndex() {
        guard let url = Bundle.main.url(forResource: "crossword-packs-index", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let index = try? JSONDecoder().decode(CrosswordPacksIndex.self, from: data) else {
            return
        }
        packsIndex = index
        // Pre-populate puzzle pool from packs so getPuzzle(for:) works with pack puzzles
        populatePuzzlesFromPacks(index)
    }

    private func populatePuzzlesFromPacks(_ index: CrosswordPacksIndex) {
        for meta in index.packs {
            guard let pack = getPack(id: meta.packId) else { continue }
            let puzzles = pack.toCrosswordPuzzles()
            for puzzle in puzzles {
                puzzlesByDifficulty[puzzle.difficulty, default: []].append(puzzle)
            }
        }
    }

    private func loadBundledPuzzles() {
        guard let url = Bundle.main.url(forResource: "crossword-puzzles", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bank = try? JSONDecoder().decode(CrosswordPuzzleBankJSON.self, from: data) else {
            return
        }
        // Append legacy puzzles; avoid duplicates if packs already populated these difficulties
        for puzzle in bank.mini where !puzzlesByDifficulty[.mini, default: []].contains(where: { $0.id == puzzle.id }) {
            puzzlesByDifficulty[.mini, default: []].append(puzzle)
        }
        for puzzle in bank.standard where !puzzlesByDifficulty[.standard, default: []].contains(where: { $0.id == puzzle.id }) {
            puzzlesByDifficulty[.standard, default: []].append(puzzle)
        }
    }

    private func loadPlayedIDs() -> Set<String> {
        persistence.load(Set<String>.self, key: PersistenceService.Keys.crosswordPlayedPuzzleIDs) ?? []
    }

    private func markAsPlayed(puzzleID: String) {
        var played = loadPlayedIDs()
        played.insert(puzzleID)
        // Reset when all puzzles have been played
        let total = puzzlesByDifficulty.values.flatMap { $0 }.count
        if total > 0 && played.count >= total { played = [] }
        persistence.save(played, key: PersistenceService.Keys.crosswordPlayedPuzzleIDs)
    }
}

private struct CrosswordPuzzleBankJSON: Codable {
    let mini: [CrosswordPuzzle]
    let standard: [CrosswordPuzzle]
}

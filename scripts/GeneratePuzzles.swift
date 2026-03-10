#!/usr/bin/env swift
// Generates a bundled puzzle bank for the SmartGames app.
// Usage: swift scripts/GeneratePuzzles.swift
// Output: SmartGames/Resources/Sudoku/puzzles.json

import Foundation

// MARK: - Inline board utilities (no app target import needed)

struct GenBoardUtils {
    static func candidates(row: Int, col: Int, in board: [[Int]]) -> Set<Int> {
        guard board[row][col] == 0 else { return [] }
        var used = Set<Int>()
        for c in 0..<9 { if board[row][c] != 0 { used.insert(board[row][c]) } }
        for r in 0..<9 { if board[r][col] != 0 { used.insert(board[r][col]) } }
        let br = (row / 3) * 3, bc = (col / 3) * 3
        for r in br..<(br + 3) {
            for c in bc..<(bc + 3) {
                if board[r][c] != 0 { used.insert(board[r][c]) }
            }
        }
        return Set(1...9).subtracting(used)
    }
}

// MARK: - Solver

class GenSolver {
    func countSolutions(_ board: [[Int]], limit: Int = 2) -> Int {
        var g = board, count = 0
        countBT(&g, count: &count, limit: limit)
        return count
    }

    private func bestCell(_ g: [[Int]]) -> (Int, Int)? {
        var best: (Int, Int)?
        var bestN = 10
        for r in 0..<9 {
            for c in 0..<9 {
                guard g[r][c] == 0 else { continue }
                let n = GenBoardUtils.candidates(row: r, col: c, in: g).count
                if n == 0 { return nil }
                if n < bestN { bestN = n; best = (r, c) }
            }
        }
        return best
    }

    private func countBT(_ g: inout [[Int]], count: inout Int, limit: Int) {
        guard count < limit else { return }
        guard let (r, c) = bestCell(g) else {
            if g.flatMap({ $0 }).allSatisfy({ $0 != 0 }) { count += 1 }
            return
        }
        for num in GenBoardUtils.candidates(row: r, col: c, in: g) {
            g[r][c] = num
            countBT(&g, count: &count, limit: limit)
            g[r][c] = 0
            if count >= limit { return }
        }
    }
}

// MARK: - Generator

class GenGenerator {
    let solver = GenSolver()

    func generate(targetGivens: Int) -> (givens: [[Int]], solution: [[Int]])? {
        var sol = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        guard fill(&sol) else { return nil }
        let givens = removeClues(sol, target: targetGivens)
        return (givens, sol)
    }

    private func fill(_ g: inout [[Int]]) -> Bool {
        for r in 0..<9 {
            for c in 0..<9 {
                guard g[r][c] == 0 else { continue }
                for num in Array(GenBoardUtils.candidates(row: r, col: c, in: g)).shuffled() {
                    g[r][c] = num
                    if fill(&g) { return true }
                    g[r][c] = 0
                }
                return false
            }
        }
        return true
    }

    private func removeClues(_ solution: [[Int]], target: Int) -> [[Int]] {
        var g = solution
        let positions = (0..<81).map { ($0 / 9, $0 % 9) }.shuffled()
        var count = 81
        for (r, c) in positions {
            guard count > target else { break }
            let bak = g[r][c]
            g[r][c] = 0
            count -= 1
            if solver.countSolutions(g, limit: 2) != 1 {
                g[r][c] = bak
                count += 1
            }
        }
        return g
    }
}

// MARK: - JSON output models

struct PuzzleEntry: Codable { let id: String; let givens: [[Int]]; let solution: [[Int]] }
struct Bank: Codable {
    let easy: [PuzzleEntry]
    let medium: [PuzzleEntry]
    let hard: [PuzzleEntry]
    let expert: [PuzzleEntry]
}

// MARK: - Main generation loop

let difficulties: [(name: String, target: Int, count: Int)] = [
    ("easy",   40, 50),
    ("medium", 30, 30),
    ("hard",   24, 20),
    ("expert", 20, 10)
]

var results: [String: [PuzzleEntry]] = [:]

for (name, target, needed) in difficulties {
    print("Generating \(needed) \(name) puzzles (target givens: \(target))...")
    let gen = GenGenerator()
    var entries: [PuzzleEntry] = []
    var attempts = 0
    while entries.count < needed && attempts < needed * 5 {
        attempts += 1
        if let (givens, solution) = gen.generate(targetGivens: target) {
            entries.append(PuzzleEntry(id: UUID().uuidString, givens: givens, solution: solution))
            if entries.count % 10 == 0 { print("  \(entries.count)/\(needed)") }
        }
    }
    results[name] = entries
    print("  Done: \(entries.count) puzzles generated")
}

let bank = Bank(
    easy:   results["easy"]   ?? [],
    medium: results["medium"] ?? [],
    hard:   results["hard"]   ?? [],
    expert: results["expert"] ?? []
)

let outputURL = URL(fileURLWithPath: "SmartGames/Resources/Sudoku/puzzles.json")
try? FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(),
                                          withIntermediateDirectories: true)
let encoder = JSONEncoder()
let data = try encoder.encode(bank)
try data.write(to: outputURL)

let total = bank.easy.count + bank.medium.count + bank.hard.count + bank.expert.count
print("\nPuzzle bank written to SmartGames/Resources/Sudoku/puzzles.json")
print("Total: \(total) puzzles (\(bank.easy.count) easy, \(bank.medium.count) medium, \(bank.hard.count) hard, \(bank.expert.count) expert)")

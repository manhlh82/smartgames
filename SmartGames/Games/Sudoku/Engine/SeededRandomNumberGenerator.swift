import Foundation

/// Deterministic pseudo-random number generator using xorshift64 algorithm.
/// Same seed always produces the same sequence — used for daily challenge puzzles.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid zero state (xorshift64 degenerates at 0)
        self.state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        // xorshift64 — fast, uniform distribution, well-tested
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    /// Derives a stable UInt64 seed from a UTC date string like "2026-03-11".
    /// Uses DJB2 hash — simple, fast, stable across platforms.
    static func seed(from dateString: String) -> UInt64 {
        var hash: UInt64 = 5381
        for byte in dateString.utf8 {
            hash = hash &* 33 &+ UInt64(byte)
        }
        return hash == 0 ? 1 : hash
    }
}

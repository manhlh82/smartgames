import Foundation

/// Handles saving and loading of all game state. Full implementation in PR-02.
final class PersistenceService: ObservableObject {
    func save<T: Codable>(_ value: T, key: String) {}
    func load<T: Codable>(_ type: T.Type, key: String) -> T? { nil }
    func delete(key: String) {}
}

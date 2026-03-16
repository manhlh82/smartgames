import Foundation
import ObjectiveC

/// Manages in-app language override.
/// Applies immediately via Bundle swizzle — no app restart needed.
/// All SwiftUI Text("key") views automatically pick up the change on next render.
/// Future games benefit automatically as long as they use standard localisation keys.
final class LocalizationService: ObservableObject {
    @Published private(set) var currentLanguageCode: String?
    /// Incremented on each language change to force full SwiftUI tree re-render.
    @Published private(set) var refreshID: UUID = UUID()

    private let persistence: PersistenceService

    init(persistence: PersistenceService) {
        self.persistence = persistence
        let saved = persistence.load(String.self, key: PersistenceService.Keys.appLanguageCode)
        self.currentLanguageCode = saved
        BundleLanguageAdapter.setOverride(languageCode: saved)
    }

    /// "System Default" when nil, otherwise the native name of the selected language.
    var currentDisplayName: String {
        guard let code = currentLanguageCode else { return "System Default" }
        return AppLanguage.supported.first(where: { $0.code == code })?.nativeName ?? code
    }

    func setLanguage(_ code: String?) {
        currentLanguageCode = code
        if let code {
            persistence.save(code, key: PersistenceService.Keys.appLanguageCode)
        } else {
            persistence.delete(key: PersistenceService.Keys.appLanguageCode)
        }
        BundleLanguageAdapter.setOverride(languageCode: code)
        refreshID = UUID()
    }

    func availableLanguages() -> [AppLanguage] {
        AppLanguage.supported
    }
}

// MARK: - Bundle Language Adapter

/// Intercepts NSLocalizedString calls on Bundle.main to redirect to the selected language bundle.
/// Uses object_setClass — a well-known iOS pattern for runtime bundle override.
private final class BundleLanguageAdapter: Bundle {
    private static var languageBundle: Bundle?

    static func setOverride(languageCode: String?) {
        // Swap Bundle.main's class to our adapter (safe to call multiple times)
        object_setClass(Bundle.main, BundleLanguageAdapter.self)

        guard let code = languageCode,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            languageBundle = nil
            return
        }
        languageBundle = bundle
    }

    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundle = BundleLanguageAdapter.languageBundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        let result = bundle.localizedString(forKey: key, value: nil, table: tableName)
        // Fall back to English (super) if key is missing in target language
        return result == key ? super.localizedString(forKey: key, value: value, table: tableName) : result
    }
}

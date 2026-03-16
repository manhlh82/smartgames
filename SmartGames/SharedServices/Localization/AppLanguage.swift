/// A supported app language with display metadata.
struct AppLanguage: Identifiable, Equatable {
    let code: String        // BCP-47, e.g. "en", "vi", "zh-Hans"
    let nativeName: String  // Name in the language itself, e.g. "Tiếng Việt"
    let englishName: String // English name for fallback display

    var id: String { code }

    /// All languages supported in Phase 1.
    static let supported: [AppLanguage] = [
        AppLanguage(code: "en",      nativeName: "English",         englishName: "English"),
        AppLanguage(code: "vi",      nativeName: "Tiếng Việt",      englishName: "Vietnamese"),
        AppLanguage(code: "es",      nativeName: "Español",         englishName: "Spanish"),
        AppLanguage(code: "ja",      nativeName: "日本語",            englishName: "Japanese"),
        AppLanguage(code: "zh-Hans", nativeName: "简体中文",           englishName: "Simplified Chinese"),
        AppLanguage(code: "pt-BR",   nativeName: "Português (BR)",  englishName: "Portuguese (Brazil)"),
    ]
}

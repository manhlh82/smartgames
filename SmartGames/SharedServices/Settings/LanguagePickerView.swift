import SwiftUI

/// Language selection screen — shown from Settings → Language.
/// Displays each language in its native script with English subtitle.
struct LanguagePickerView: View {
    @EnvironmentObject var localization: LocalizationService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // "System Default" option resets to device locale
            languageRow(code: nil, nativeName: "System Default", englishName: "Follow device language")

            ForEach(localization.availableLanguages()) { language in
                languageRow(code: language.code,
                            nativeName: language.nativeName,
                            englishName: language.englishName)
            }
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func languageRow(code: String?, nativeName: String, englishName: String) -> some View {
        Button {
            localization.setLanguage(code)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(nativeName)
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)
                    Text(englishName)
                        .font(.appCaption)
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
                if localization.currentLanguageCode == code {
                    Image(systemName: "checkmark")
                        .foregroundColor(.appAccent)
                }
            }
        }
        .accessibilityLabel("\(nativeName), \(englishName)")
    }
}

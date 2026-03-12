import SwiftUI

/// App settings screen — accessible from hub gear icon.
struct SettingsView: View {
    @EnvironmentObject var settings: SettingsService
    @EnvironmentObject var store: StoreService

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Gameplay") {
                    Toggle("Sound Effects", isOn: $settings.isSoundEnabled)
                    Toggle("Haptics", isOn: $settings.isHapticsEnabled)
                }

                Section("Display") {
                    Toggle("Highlight Related Cells", isOn: $settings.highlightRelatedCells)
                    Toggle("Highlight Same Numbers", isOn: $settings.highlightSameNumbers)
                    Toggle("Show Timer", isOn: $settings.showTimer)
                }

                Section("Premium") {
                    if store.hasRemovedAds {
                        Label("Ads Removed", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Remove Ads", systemImage: "nosign")
                        }
                    }
                    Button {
                        showPaywall = true
                    } label: {
                        Label("Get Hint Pack (12 Hints)", systemImage: "lightbulb.fill")
                    }
                }

                Section("Legal") {
                    Link("Privacy Policy", destination: URL(string: "https://smartgames.app/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://smartgames.app/terms")!)
                }

                Section {
                    HStack {
                        Spacer()
                        Text("SmartGames v1.0")
                            .font(.appCaption)
                            .foregroundColor(.appTextSecondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
        }
    }
}

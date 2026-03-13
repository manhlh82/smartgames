import SwiftUI

// MARK: - ThemePickerView

/// Full-screen theme picker with 2-column grid, lock states, purchase flow, and Gold balance.
struct ThemePickerView: View {
    @EnvironmentObject var themeService: ThemeService
    @EnvironmentObject var gold: GoldService

    /// Theme pending purchase confirmation.
    @State private var pendingPurchase: BoardThemeName?
    /// Alert for insufficient funds.
    @State private var insufficientFundsTheme: BoardThemeName?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Balance header
                HStack {
                    Text("Themes")
                        .font(.appHeadline)
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                    GoldBalanceView()
                }
                .padding(.horizontal, 4)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(BoardThemeName.allCases) { name in
                        ThemeSwatchCell(
                            name: name,
                            isSelected: themeService.themeName == name,
                            isUnlocked: themeService.isUnlocked(name)
                        )
                        .onTapGesture { handleTap(name) }
                        .accessibilityLabel(accessibilityLabel(for: name))
                        .accessibilityAddTraits(themeService.themeName == name ? .isSelected : [])
                    }
                }
            }
            .padding(16)
        }
        // Purchase confirmation alert
        .alert(
            purchaseAlertTitle,
            isPresented: Binding(
                get: { pendingPurchase != nil },
                set: { if !$0 { pendingPurchase = nil } }
            )
        ) {
            Button("Buy") { confirmPurchase() }
            Button("Cancel", role: .cancel) { pendingPurchase = nil }
        } message: {
            if let theme = pendingPurchase {
                Text("You have \(gold.balance) Gold.")
            }
        }
        // Insufficient funds alert
        .alert(
            "Not Enough Gold",
            isPresented: Binding(
                get: { insufficientFundsTheme != nil },
                set: { if !$0 { insufficientFundsTheme = nil } }
            )
        ) {
            Button("OK", role: .cancel) { insufficientFundsTheme = nil }
        } message: {
            if let theme = insufficientFundsTheme {
                let deficit = theme.price - gold.balance
                Text("You need \(deficit) more Gold to unlock \(theme.displayName).")
            }
        }
    }

    // MARK: - Actions

    private func handleTap(_ name: BoardThemeName) {
        if themeService.isUnlocked(name) {
            themeService.setTheme(name)
        } else if gold.balance >= name.price {
            pendingPurchase = name
        } else {
            insufficientFundsTheme = name
        }
    }

    private func confirmPurchase() {
        guard let theme = pendingPurchase else { return }
        let result = themeService.purchase(theme)
        if result == .success {
            themeService.setTheme(theme)
        }
        pendingPurchase = nil
    }

    // MARK: - Computed

    private var purchaseAlertTitle: String {
        guard let theme = pendingPurchase else { return "" }
        return "Unlock \(theme.displayName) for \(theme.price) Gold?"
    }

    private func accessibilityLabel(for name: BoardThemeName) -> String {
        if themeService.isUnlocked(name) {
            return "\(name.displayName) theme\(themeService.themeName == name ? ", selected" : "")"
        }
        return "\(name.displayName) theme - Locked, \(name.price) Gold"
    }
}

// MARK: - ThemeSwatchCell

/// Individual theme card: mini board preview + name + lock overlay.
private struct ThemeSwatchCell: View {
    let name: BoardThemeName
    let isSelected: Bool
    let isUnlocked: Bool

    private var theme: BoardTheme { BoardTheme.theme(for: name) }

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                // Mini board preview
                MiniBoardView(theme: theme)
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: isSelected ? 2.5 : 1.0)
                    )
                    .overlay(lockOverlay)

                // Selected checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.appAccent)
                        .background(Circle().fill(Color.white).padding(2))
                        .offset(x: 6, y: 6)
                }
            }

            // Theme name
            Text(name.displayName)
                .font(.appCaption)
                .fontWeight(.medium)
                .foregroundColor(.appTextPrimary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var lockOverlay: some View {
        if !isUnlocked {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        Text("\(name.price)")
                            .font(.appCaption)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                )
        }
    }

    private var borderColor: Color {
        if isSelected { return .appAccent }
        if !isUnlocked { return Color.gray.opacity(0.3) }
        return Color.gray.opacity(0.4)
    }
}

// MARK: - MiniBoardView

/// 3×3 mini board swatch showing the theme's cell and highlight colors.
private struct MiniBoardView: View {
    let theme: BoardTheme

    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<3, id: \.self) { col in
                        let isCenter = row == 1 && col == 1
                        Rectangle()
                            .fill(isCenter ? theme.selectedCell : theme.cellBackground)
                    }
                }
            }
        }
        .background(theme.thickGridLine)
        .padding(2)
        .background(theme.boardBackground)
    }
}

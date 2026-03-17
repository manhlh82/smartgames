import SwiftUI

// MARK: - ThemePickerView

/// Full-screen theme picker with 2-column grid, lock states, purchase flow, currency balance, and rarity badges.
struct ThemePickerView: View {
    @EnvironmentObject var themeService: ThemeService
    @EnvironmentObject var gold: GoldService
    @EnvironmentObject var diamonds: DiamondService

    /// Theme pending purchase confirmation.
    @State private var pendingPurchase: BoardThemeName?
    /// Alert for insufficient funds.
    @State private var insufficientFundsTheme: BoardThemeName?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Balance header — diamonds bright, gold subdued
                HStack {
                    Text("Themes")
                        .font(.appHeadline)
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                    CurrencyBarView()
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
            if let pp = pendingPurchase {
                if pp.diamondPrice != nil {
                    Text("You have \(diamonds.balance) Diamonds.")
                } else {
                    Text("You have \(gold.balance) Gold.")
                }
            }
        }
        // Insufficient funds alert
        .alert(
            insufficientFundsTheme?.diamondPrice != nil ? "Not Enough Diamonds" : "Not Enough Gold",
            isPresented: Binding(
                get: { insufficientFundsTheme != nil },
                set: { if !$0 { insufficientFundsTheme = nil } }
            )
        ) {
            Button("OK", role: .cancel) { insufficientFundsTheme = nil }
        } message: {
            if let theme = insufficientFundsTheme {
                if let dp = theme.diamondPrice {
                    let deficit = dp - diamonds.balance
                    Text("You need \(deficit) more Diamonds to unlock \(theme.displayName).")
                } else {
                    let deficit = theme.price - gold.balance
                    Text("You need \(deficit) more Gold to unlock \(theme.displayName).")
                }
            }
        }
    }

    // MARK: - Actions

    private func handleTap(_ name: BoardThemeName) {
        if themeService.isUnlocked(name) {
            themeService.setTheme(name)
        } else if let dp = name.diamondPrice {
            // Legendary: purchase with diamonds
            if diamonds.balance >= dp {
                pendingPurchase = name
            } else {
                insufficientFundsTheme = name
            }
        } else if gold.balance >= name.price {
            pendingPurchase = name
        } else {
            insufficientFundsTheme = name
        }
    }

    private func confirmPurchase() {
        guard let theme = pendingPurchase else { return }
        if theme.diamondPrice != nil {
            let result = themeService.purchaseWithDiamonds(theme)
            if result == .success { themeService.setTheme(theme) }
        } else {
            let result = themeService.purchase(theme)
            if result == .success { themeService.setTheme(theme) }
        }
        pendingPurchase = nil
    }

    // MARK: - Computed

    private var purchaseAlertTitle: String {
        guard let theme = pendingPurchase else { return "" }
        if let dp = theme.diamondPrice {
            return "Unlock \(theme.displayName) for \(dp) Diamonds?"
        }
        return "Unlock \(theme.displayName) for \(theme.price) Gold?"
    }

    private func accessibilityLabel(for name: BoardThemeName) -> String {
        if themeService.isUnlocked(name) {
            return "\(name.displayName) theme\(themeService.themeName == name ? ", selected" : "")"
        }
        if let dp = name.diamondPrice {
            return "\(name.displayName) theme - Locked, \(dp) Diamonds"
        }
        return "\(name.displayName) theme - Locked, \(name.price) Gold"
    }
}

// MARK: - ThemeSwatchCell

/// Individual theme card: mini board preview + rarity border + name + lock overlay + EXCLUSIVE badge.
private struct ThemeSwatchCell: View {
    let name: BoardThemeName
    let isSelected: Bool
    let isUnlocked: Bool

    private var theme: BoardTheme { BoardTheme.theme(for: name) }
    private var rarity: CosmeticRarity { name.rarity }

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                // Mini board preview
                MiniBoardView(theme: theme)
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(rarityBorder, lineWidth: isSelected ? 2.5 : rarityBorderWidth)
                    )
                    .overlay(lockOverlay)
                    .overlay(alignment: .topLeading) { rarityBadge }

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
    private var rarityBadge: some View {
        if rarity == .legendary && isUnlocked {
            Text("EXCLUSIVE")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
                .padding(4)
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
                        if let dp = name.diamondPrice {
                            HStack(spacing: 2) {
                                Image(systemName: "diamond.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.cyan)
                                Text("\(dp)")
                                    .font(.appCaption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.cyan)
                            }
                        } else {
                            Text("\(name.price)")
                                .font(.appCaption)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                        }
                    }
                )
        }
    }

    private var rarityBorder: AnyShapeStyle {
        if isSelected { return AnyShapeStyle(Color.appAccent) }
        switch rarity {
        case .legendary:
            return AnyShapeStyle(
                LinearGradient(colors: [.purple, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        case .rare:
            return AnyShapeStyle(Color.orange.opacity(isUnlocked ? 0.7 : 0.3))
        case .common:
            return AnyShapeStyle(Color.gray.opacity(isUnlocked ? 0.4 : 0.3))
        }
    }

    private var rarityBorderWidth: CGFloat {
        switch rarity {
        case .legendary: return 1.8
        case .rare: return 1.4
        case .common: return 1.0
        }
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

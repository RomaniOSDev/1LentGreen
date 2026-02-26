//
//  LentGreenTheme.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI

// MARK: - Colors
extension Color {
    /// #141B1F — main background
    static let lentBackground = Color(red: 0.078, green: 0.106, blue: 0.122)
    /// #11E94E — accent green (success, buttons, repaid)
    static let lentGreen = Color(red: 0.067, green: 0.914, blue: 0.306)
    /// #233036 — card background, secondary elements
    static let lentCard = Color(red: 0.137, green: 0.188, blue: 0.212)
    /// Darker card for inner layers
    static let lentCardDark = Color(red: 0.098, green: 0.137, blue: 0.157)
}

// MARK: - Gradients
extension LinearGradient {
    static let lentBackgroundGradient = LinearGradient(
        colors: [
            Color.lentBackground,
            Color(red: 0.06, green: 0.08, blue: 0.10)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let lentCardGradient = LinearGradient(
        colors: [
            Color.lentCard,
            Color.lentCard.opacity(0.85),
            Color.lentCardDark
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let lentGreenGradient = LinearGradient(
        colors: [
            Color.lentGreen,
            Color.lentGreen.opacity(0.85),
            Color(red: 0.05, green: 0.75, blue: 0.25)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let lentGreenSoft = LinearGradient(
        colors: [
            Color.lentGreen.opacity(0.4),
            Color.lentGreen.opacity(0.15)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let lentTitleGradient = LinearGradient(
        colors: [Color.lentGreen, Color.lentGreen.opacity(0.7)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Shadow & depth modifiers
extension View {
    /// Floating card: shadow + subtle border
    func lentCardShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
            .shadow(color: Color.lentGreen.opacity(0.08), radius: 20, x: 0, y: 4)
    }

    /// Softer shadow for list rows
    func lentSoftShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    /// Strong shadow for FAB / primary buttons
    func lentFloatingShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 8)
            .shadow(color: Color.lentGreen.opacity(0.25), radius: 12, x: 0, y: 4)
    }

    /// Inner depth (for cards that feel recessed)
    func lentInnerDepth() -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    .blendMode(.overlay)
            )
    }
}

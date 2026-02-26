//
//  OnboardingView.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        ("list.bullet.rectangle.fill", "Track Debts", "Keep all your loans and debts in one place. See who owes you and whom you owe."),
        ("person.2.fill", "People & Reminders", "Add people once and link multiple debts. Get reminded when payment is due."),
        ("chart.pie.fill", "Stay in Control", "View statistics, use templates, and manage everything from a simple home screen.")
    ]

    var body: some View {
        ZStack {
            LinearGradient.lentBackgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(
                            icon: pages[index].icon,
                            title: pages[index].title,
                            subtitle: pages[index].subtitle
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                PageIndicator(current: currentPage, total: pages.count)
                    .padding(.top, 24)

                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient.lentGreenGradient)
                        )
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .lentSoftShadow()
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

struct OnboardingPageView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.lentGreen.opacity(0.25),
                                Color.lentGreen.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(LinearGradient.lentTitleGradient)
            }
            .shadow(color: Color.lentGreen.opacity(0.2), radius: 24, x: 0, y: 8)

            VStack(spacing: 12) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }
            Spacer()
            Spacer()
        }
    }
}

struct PageIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.lentGreen : Color.lentCard)
                    .frame(width: index == current ? 10 : 8, height: index == current ? 10 : 8)
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}

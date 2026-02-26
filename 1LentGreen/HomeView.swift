//
//  HomeView.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: LentGreenViewModel
    @State private var showQuickAdd = false
    @State private var showAddDebt = false
    @State private var selectedDebt: Debt?

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    private var shortDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.lentBackgroundGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        balanceSection
                        quickActionsSection
                        dueSoonSection
                        recentSection
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.lentBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showQuickAdd) {
                QuickAddDebtView(viewModel: viewModel)
            }
            .sheet(isPresented: $showAddDebt) {
                AddDebtView(viewModel: viewModel, mode: .add)
            }
            .navigationDestination(item: $selectedDebt) { debt in
                DebtDetailView(viewModel: viewModel, debt: debt)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LentGreen")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.lentGreen, .lentGreen.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text(summarySubtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var summarySubtitle: String {
        let active = viewModel.activeDebts.count
        if active == 0 {
            return "All clear. No active debts."
        }
        return active == 1 ? "1 active debt" : "\(active) active debts"
    }

    private var balanceSection: some View {
        VStack(spacing: 14) {
            Text("Balance")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(formatBalance(viewModel.netBalance))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(balanceColor(viewModel.netBalance))

            HStack(spacing: 12) {
                HomeStatPill(
                    title: "Owed to me",
                    value: viewModel.totalOwedToMe,
                    icon: "arrow.down.circle.fill"
                )
                HomeStatPill(
                    title: "I owe",
                    value: viewModel.totalIOwe,
                    icon: "arrow.up.circle.fill"
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient.lentCardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color.lentGreen.opacity(0.25), Color.lentGreen.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(20)
        .lentCardShadow()
        .padding(.horizontal, 20)
    }

    private func formatBalance(_ value: Double) -> String {
        let sign = value >= 0 ? "" : "−"
        return "\(sign)\(Int(abs(value))) ₽"
    }

    private func balanceColor(_ value: Double) -> Color {
        if value > 0 { return .lentGreen }
        if value < 0 { return Color(white: 0.7) }
        return .gray
    }

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            Button {
                showQuickAdd = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.title3)
                    Text("Quick add")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
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

            Button {
                showAddDebt = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Full form")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient.lentCardGradient)
                )
                .foregroundColor(.lentGreen)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [Color.lentGreen.opacity(0.6), Color.lentGreen.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
            .lentSoftShadow()
        }
        .padding(.horizontal, 20)
    }

    private var dueSoonSection: some View {
        Group {
            let dueSoon = viewModel.debtsDueSoon(withinDays: 7)
            if !dueSoon.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundStyle(LinearGradient.lentTitleGradient)
                        Text("Due soon")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 8) {
                        ForEach(dueSoon.prefix(5)) { debt in
                            HomeDebtRow(
                                debt: debt,
                                dateFormatter: shortDateFormatter,
                                subtitle: debt.dueDate.map { "Due \(shortDateFormatter.string(from: $0))" }
                            )
                            .onTapGesture { selectedDebt = debt }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient.lentCardGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.lentGreen.opacity(0.12), lineWidth: 1)
                )
                .cornerRadius(16)
                .lentSoftShadow()
                .padding(.horizontal, 20)
            }
        }
    }

    private var recentSection: some View {
        Group {
            let recent = viewModel.recentDebts(limit: 5)
            if !recent.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundStyle(LinearGradient.lentTitleGradient)
                        Text("Recent")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 8) {
                        ForEach(recent) { debt in
                            HomeDebtRow(
                                debt: debt,
                                dateFormatter: shortDateFormatter,
                                subtitle: dateFormatter.string(from: debt.date)
                            )
                            .onTapGesture { selectedDebt = debt }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient.lentCardGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.lentGreen.opacity(0.12), lineWidth: 1)
                )
                .cornerRadius(16)
                .lentSoftShadow()
                .padding(.horizontal, 20)
            }
        }
    }
}

struct HomeStatPill: View {
    let title: String
    let value: Double
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(LinearGradient.lentTitleGradient)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text("\(Int(value)) ₽")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.lentBackground.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.lentGreen.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct HomeDebtRow: View {
    let debt: Debt
    let dateFormatter: DateFormatter
    let subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.lentCard, Color.lentCardDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(Color.lentGreen.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                Text(debt.personName.prefix(1).uppercased())
                    .font(.headline)
                    .foregroundColor(.lentGreen)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(debt.personName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                if let sub = subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(debt.remainingAmount)) \(debt.currency)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(debt.status == .repaid ? .gray : .white)
                Image(systemName: debt.type.icon)
                    .font(.caption)
                    .foregroundColor(.lentGreen)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.lentBackground.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

#Preview {
    HomeView(viewModel: LentGreenViewModel())
}

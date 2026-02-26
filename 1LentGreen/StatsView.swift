//
//  StatsView.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var viewModel: LentGreenViewModel
    @State private var statsPeriod: LentGreenViewModel.StatsPeriod = .thisMonth

    private var periodDebts: [Debt] {
        viewModel.debts(in: statsPeriod)
    }

    private var monthlyData: [(month: String, total: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: periodDebts) { debt in
            calendar.component(.month, from: debt.date)
        }
        return (1...12).compactMap { month -> (String, Double)? in
            guard let debts = grouped[month] else { return nil }
            let sum = debts.filter { $0.status == .active || $0.status == .partiallyRepaid }.reduce(0) { $0 + $1.remainingAmount }
            guard sum > 0 else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let date = calendar.date(from: DateComponents(month: month)) ?? Date()
            return (formatter.string(from: date), sum)
        }
    }

    private var statusCounts: [(DebtStatus, Int)] {
        let active = periodDebts.filter { $0.status == .active || $0.status == .partiallyRepaid }.count
        let repaid = periodDebts.filter { $0.status == .repaid }.count
        let writtenOff = periodDebts.filter { $0.status == .writtenOff }.count
        return [(.active, active), (.repaid, repaid), (.writtenOff, writtenOff)].filter { $0.1 > 0 }
    }

    private var tagBreakdown: [(tag: String, amount: Double)] {
        viewModel.breakdownByTag(in: statsPeriod)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.lentBackgroundGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        Picker("Period", selection: $statsPeriod) {
                            ForEach(LentGreenViewModel.StatsPeriod.allCases, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .tint(.lentGreen)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(title: "Owed to me", amount: viewModel.totalOwedToMe(in: statsPeriod), icon: "arrow.down.circle.fill")
                            StatCard(title: "I owe", amount: viewModel.totalIOwe(in: statsPeriod), icon: "arrow.up.circle.fill")
                            StatCard(title: "Balance", amount: viewModel.totalOwedToMe(in: statsPeriod) - viewModel.totalIOwe(in: statsPeriod), icon: "scale.3d")
                            StatCard(title: "Repaid (period)", amount: viewModel.totalRepaid(in: statsPeriod), icon: "checkmark.circle.fill")
                        }

                        if !monthlyData.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("By month")
                                    .foregroundColor(.lentGreen)
                                    .font(.headline)
                                Chart(monthlyData, id: \.month) { item in
                                    BarMark(
                                        x: .value("Month", item.month),
                                        y: .value("Amount", item.total)
                                    )
                                    .foregroundStyle(Color.lentGreen)
                                }
                                .frame(height: 180)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(LinearGradient.lentCardGradient)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.lentGreen.opacity(0.12), lineWidth: 1)
                            )
                            .cornerRadius(14)
                            .lentSoftShadow()
                        }

                        if !statusCounts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("By status")
                                    .foregroundColor(.lentGreen)
                                    .font(.headline)
                                Chart(statusCounts, id: \.0.rawValue) { item in
                                    SectorMark(
                                        angle: .value("Count", item.1),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 1
                                    )
                                    .foregroundStyle(by: .value("Status", item.0.rawValue))
                                    .cornerRadius(4)
                                }
                                .chartForegroundStyleScale([
                                    "Active": Color.lentGreen,
                                    "Repaid": Color.lentGreen.opacity(0.6),
                                    "Written off": Color.lentGreen.opacity(0.3)
                                ])
                                .frame(height: 160)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(LinearGradient.lentCardGradient)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.lentGreen.opacity(0.12), lineWidth: 1)
                            )
                            .cornerRadius(14)
                            .lentSoftShadow()
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top debtors & creditors")
                                .foregroundColor(.lentGreen)
                                .font(.headline)
                            ForEach(viewModel.topPeople(in: statsPeriod)) { item in
                                HStack {
                                    Text(item.name)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(item.amount)) ₽")
                                        .foregroundColor(.lentGreen)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient.lentCardGradient)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.lentGreen.opacity(0.12), lineWidth: 1)
                        )
                        .cornerRadius(14)
                        .lentSoftShadow()
                        .padding(.horizontal)

                        if !tagBreakdown.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("By tag")
                                    .foregroundColor(.lentGreen)
                                    .font(.headline)
                                ForEach(tagBreakdown, id: \.tag) { item in
                                    HStack {
                                        Text(item.tag)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(Int(item.amount)) ₽")
                                            .foregroundColor(item.amount >= 0 ? .lentGreen : .gray)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(LinearGradient.lentCardGradient)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.lentGreen.opacity(0.12), lineWidth: 1)
                            )
                            .cornerRadius(14)
                            .lentSoftShadow()
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.lentBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .foregroundStyle(Color.lentGreen)
        }
    }
}

//
//  DebtListView.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI

struct DebtListView: View {
    @ObservedObject var viewModel: LentGreenViewModel
    @State private var showAddDebt = false
    @State private var showQuickAdd = false
    @State private var selectedDebt: Debt?
    @State private var debtToDelete: Debt?
    @State private var showDeleteAlert = false

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient.lentBackgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Text("LentGreen")
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(LinearGradient.lentTitleGradient)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            StatCard(title: "Owed to me", amount: viewModel.totalOwedToMe, icon: "arrow.down.circle.fill")
                            StatCard(title: "I owe", amount: viewModel.totalIOwe, icon: "arrow.up.circle.fill")
                        }
                        .padding(.horizontal)

                        Picker("Filter", selection: $viewModel.selectedFilter) {
                            ForEach(LentGreenViewModel.FilterType.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .tint(.lentGreen)

                        Menu {
                            ForEach(LentGreenViewModel.SortOrder.allCases, id: \.self) { order in
                                Button {
                                    viewModel.sortOrder = order
                                } label: {
                                    HStack {
                                        Text(order.rawValue)
                                        if viewModel.sortOrder == order {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("Sort: \(viewModel.sortOrder.rawValue)")
                                    .foregroundColor(.lentGreen)
                                    .font(.subheadline)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.lentGreen)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal)

                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredDebts) { debt in
                                DebtRowView(debt: debt, dateFormatter: dateFormatter)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedDebt = debt
                                    }
                                    .contextMenu {
                                        if debt.status != .repaid && debt.status != .writtenOff {
                                            Button {
                                                viewModel.markAsRepaid(debt)
                                            } label: {
                                                Label("Repay", systemImage: "checkmark.circle.fill")
                                            }
                                        }
                                        Button(role: .destructive) {
                                            debtToDelete = debt
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 80)
                    }
                    .padding(.top, 8)
                }

                HStack(spacing: 12) {
                    Button {
                        showQuickAdd = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient.lentCardGradient)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(Color.lentGreen.opacity(0.4), lineWidth: 1)
                                )
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.lentGreen)
                        }
                    }
                    .buttonStyle(.plain)
                    .lentSoftShadow()
                    .padding(.trailing, 4)
                    Button {
                        showAddDebt = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient.lentGreenGradient)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                            Image(systemName: "plus")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .lentFloatingShadow()
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .searchable(text: $viewModel.searchText, prompt: "Search by name or description")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.lentBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .foregroundStyle(Color.lentGreen)
            .sheet(isPresented: $showAddDebt) {
                AddDebtView(viewModel: viewModel, mode: .add)
            }
            .sheet(isPresented: $showQuickAdd) {
                QuickAddDebtView(viewModel: viewModel)
            }
            .navigationDestination(item: $selectedDebt) { debt in
                DebtDetailView(viewModel: viewModel, debt: debt)
            }
            .alert("Delete debt?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { debtToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let d = debtToDelete { viewModel.deleteDebt(d) }
                    debtToDelete = nil
                }
            } message: {
                if let d = debtToDelete {
                    Text("\(d.personName) — \(Int(d.remainingAmount)) \(d.currency) will be removed.")
                }
            }
        }
    }
}

struct DebtRowView: View {
    let debt: Debt
    let dateFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.lentCard, Color.lentCardDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.lentGreen.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                    Text(debt.personName.prefix(1).uppercased())
                        .foregroundColor(.lentGreen)
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(debt.personName)
                        .foregroundColor(.white)
                        .font(.headline)
                    Text(dateFormatter.string(from: debt.date))
                        .foregroundColor(.gray)
                        .font(.caption)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(debt.remainingAmount)) \(debt.currency)")
                        .foregroundColor(.white)
                        .font(.title3)
                        .bold()
                    Image(systemName: debt.type.icon)
                        .foregroundColor(.lentGreen)
                }
            }

            if debt.status == .partiallyRepaid {
                ProgressView(value: debt.progress)
                    .tint(.lentGreen)
                    .background(Color.lentCardDark)
            }

            HStack(spacing: 8) {
                StatusPill(status: debt.status)
                if !debt.tags.isEmpty {
                    ForEach(debt.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.lentBackground.opacity(0.8))
                            )
                            .foregroundColor(.gray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.lentGreen.opacity(0.15), lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(14)
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
}

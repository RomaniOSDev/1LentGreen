//
//  DebtDetailView.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI

struct DebtDetailView: View {
    @ObservedObject var viewModel: LentGreenViewModel
    let debt: Debt
    @State private var showRepaymentSheet = false
    @State private var showEditSheet = false
    @State private var currentDebt: Debt

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    init(viewModel: LentGreenViewModel, debt: Debt) {
        self.viewModel = viewModel
        self.debt = debt
        _currentDebt = State(initialValue: debt)
    }

    private var displayDebt: Debt {
        viewModel.debts.first(where: { $0.id == debt.id }) ?? currentDebt
    }

    var body: some View {
        ZStack {
            LinearGradient.lentBackgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(displayDebt.personName)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                        HStack {
                            Image(systemName: displayDebt.type.icon)
                                .foregroundStyle(LinearGradient.lentTitleGradient)
                            Text(displayDebt.type.rawValue)
                                .foregroundColor(.lentGreen)
                        }
                    }

                    VStack(spacing: 12) {
                        Text("\(Int(displayDebt.remainingAmount)) \(displayDebt.currency)")
                            .font(.system(size: 48))
                            .bold()
                            .foregroundColor(.white)

                        if displayDebt.status == .partiallyRepaid {
                            Text("Remaining: \(Int(displayDebt.remainingAmount)) \(displayDebt.currency)")
                                .foregroundColor(.lentGreen)
                            ProgressView(value: displayDebt.progress)
                                .tint(.lentGreen)
                                .background(Color.lentCardDark)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient.lentCardGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.lentGreen.opacity(0.2), Color.lentGreen.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .cornerRadius(16)
                    .lentCardShadow()

                    VStack(spacing: 12) {
                        DetailRow(icon: "calendar", title: "Date", value: dateFormatter.string(from: displayDebt.date))
                        if let due = displayDebt.dueDate {
                            DetailRow(icon: "clock", title: "Due", value: dateFormatter.string(from: due))
                        }
                        DetailRow(icon: "tag", title: "Status", value: displayDebt.status.rawValue, valueColor: displayDebt.status.color)
                        if !displayDebt.tags.isEmpty {
                            DetailRow(icon: "number", title: "Tags", value: displayDebt.tags.joined(separator: ", "))
                        }
                        if let desc = displayDebt.description, !desc.isEmpty {
                            DetailRow(icon: "doc.text", title: "Description", value: desc)
                        }
                        if !displayDebt.notes.isEmpty {
                            DetailRow(icon: "note.text", title: "Notes", value: displayDebt.notes)
                        }
                    }

                    HStack(spacing: 12) {
                        if displayDebt.status != .repaid && displayDebt.status != .writtenOff {
                            Button {
                                showRepaymentSheet = true
                            } label: {
                                Text("Repay")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .fontWeight(.semibold)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(LinearGradient.lentGreenGradient)
                                    )
                                    .foregroundColor(.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .lentSoftShadow()
                        }
                        Button {
                            showEditSheet = true
                        } label: {
                            Text("Edit")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .fontWeight(.semibold)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LinearGradient.lentCardGradient)
                                )
                                .foregroundColor(.lentGreen)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.lentGreen.opacity(0.6), Color.lentGreen.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .lentSoftShadow()
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { currentDebt = viewModel.debts.first(where: { $0.id == debt.id }) ?? debt }
        .sheet(isPresented: $showRepaymentSheet) {
            RepaymentSheet(viewModel: viewModel, debt: displayDebt)
        }
        .sheet(isPresented: $showEditSheet) {
            AddDebtView(viewModel: viewModel, mode: .edit(displayDebt))
        }
    }
}

struct RepaymentSheet: View {
    @ObservedObject var viewModel: LentGreenViewModel
    let debt: Debt
    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String = ""
    @FocusState private var amountFocused: Bool

    private var repaymentAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.lentBackgroundGradient.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Remaining: \(Int(debt.remainingAmount)) \(debt.currency)")
                        .foregroundColor(.gray)
                    TextField("Amount to repay", text: $amountText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .focused($amountFocused)
                    Button("Repay in full") {
                        viewModel.markAsRepaid(debt)
                        dismiss()
                    }
                    .foregroundColor(.lentGreen)
                    Button("Repay entered amount") {
                        if let amount = repaymentAmount, amount > 0 {
                            viewModel.markAsRepaid(debt, amount: amount)
                            dismiss()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient.lentGreenGradient)
                    )
                    .foregroundColor(.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .lentSoftShadow()
                    Spacer()
                }
                .padding(.top, 32)
            }
            .navigationTitle("Repay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.lentBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.lentGreen)
                }
            }
        }
    }
}

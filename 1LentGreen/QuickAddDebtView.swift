//
//  QuickAddDebtView.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI

struct QuickAddDebtView: View {
    @ObservedObject var viewModel: LentGreenViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lentgreen_default_currency") private var defaultCurrency: String = "₽"

    @State private var debtType: DebtType = .owedToMe
    @State private var selectedPerson: Person?
    @State private var personName: String = ""
    @State private var amount: Double = 0

    private var effectivePerson: Person? {
        if let p = selectedPerson { return p }
        let trimmed = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return viewModel.people.first { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
            ?? Person(id: UUID(), name: trimmed, phone: nil, email: nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.lentBackgroundGradient.ignoresSafeArea()
                VStack(spacing: 20) {
                    Picker("Type", selection: $debtType) {
                        Text("Owed to me").tag(DebtType.owedToMe)
                        Text("I owe").tag(DebtType.iOwe)
                    }
                    .pickerStyle(.segmented)
                    .tint(.lentGreen)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Person")
                            .foregroundColor(.gray)
                            .font(.caption)
                        if viewModel.recentPeople.isEmpty && viewModel.people.isEmpty {
                            TextField("Name", text: $personName)
                                .textFieldStyle(.roundedBorder)
                                .foregroundColor(.white)
                        } else {
                            Menu {
                                Button("New person...") {
                                    selectedPerson = nil
                                    personName = ""
                                }
                                ForEach(viewModel.recentPeople.isEmpty ? viewModel.people : viewModel.recentPeople) { p in
                                    Button(p.name) {
                                        selectedPerson = p
                                        personName = p.name
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedPerson?.name ?? (personName.isEmpty ? "Select person" : personName))
                                        .foregroundColor(selectedPerson != nil || !personName.isEmpty ? .white : .gray)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.lentGreen)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(LinearGradient.lentCardGradient)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.lentGreen.opacity(0.2), lineWidth: 1)
                                )
                                .cornerRadius(10)
                            }
                            if selectedPerson == nil && !viewModel.people.isEmpty {
                                TextField("Or type name", text: $personName)
                                    .textFieldStyle(.roundedBorder)
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Amount (\(defaultCurrency))")
                            .foregroundColor(.gray)
                            .font(.caption)
                        TextField("0", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .foregroundColor(.white)
                    }

                    Button("Add debt") {
                        save()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(amount > 0 && (selectedPerson != nil || !personName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? LinearGradient.lentGreenGradient : LinearGradient.lentCardGradient)
                    )
                    .foregroundColor(amount > 0 ? .black : .gray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(amount > 0 ? Color.white.opacity(0.2) : Color.lentGreen.opacity(0.15), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .disabled(amount <= 0)
                    .lentSoftShadow()
                    .padding(.top, 8)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Quick add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.lentBackground, for: .navigationBar)
            .foregroundStyle(Color.lentGreen)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.lentGreen)
                }
            }
        }
    }

    private func save() {
        let name: String
        let personId: UUID
        if let p = effectivePerson {
            name = p.name
            personId = p.id
            if !viewModel.people.contains(where: { $0.id == p.id }) {
                viewModel.addPerson(p)
            }
        } else {
            let trimmed = personName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, amount > 0 else { return }
            let newP = Person(id: UUID(), name: trimmed, phone: nil, email: nil)
            viewModel.addPerson(newP)
            name = trimmed
            personId = newP.id
        }
        guard amount > 0 else { return }
        let debt = Debt(
            personId: personId,
            personName: name,
            type: debtType,
            amount: amount,
            remainingAmount: amount,
            currency: defaultCurrency,
            description: nil,
            date: Date(),
            dueDate: nil,
            status: .active,
            tags: [],
            notes: ""
        )
        viewModel.addDebt(debt)
    }
}

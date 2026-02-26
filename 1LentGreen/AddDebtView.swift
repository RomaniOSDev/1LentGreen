//
//  AddDebtView.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI

struct AddDebtView: View {
    @ObservedObject var viewModel: LentGreenViewModel
    @Environment(\.dismiss) private var dismiss

    enum Mode {
        case add
        case edit(Debt)
    }

    let mode: Mode

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    @State private var debtType: DebtType = .owedToMe
    @State private var personName: String = ""
    @State private var amount: Double = 0
    @State private var currency: String = "₽"
    @State private var date: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date().addingTimeInterval(86400 * 7)
    @State private var descriptionText: String = ""
    @State private var tagsString: String = ""
    @State private var notes: String = ""
    @State private var status: DebtStatus = .active
    @State private var showAddPerson: Bool = false
    @State private var remainingAmount: Double = 0
    @State private var selectedTemplateId: UUID?

    private var selectedTemplate: DebtTemplate? {
        guard let id = selectedTemplateId else { return nil }
        return viewModel.templates.first { $0.id == id }
    }

    private var tags: [String] {
        tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.lentBackgroundGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        if !viewModel.templates.isEmpty && !isEditing {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("From template")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                Picker("Template", selection: $selectedTemplateId) {
                                    Text("None").tag(nil as UUID?)
                                    ForEach(viewModel.templates) { t in
                                        Text(t.name).tag(t.id as UUID?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.lentGreen)
                                .onChange(of: selectedTemplateId) { _, newId in
                                    guard let id = newId, let t = viewModel.templates.first(where: { $0.id == id }) else { return }
                                    debtType = t.type
                                    currency = t.currency
                                    tagsString = t.tags.joined(separator: ", ")
                                    if let p = t.personName, !p.isEmpty { personName = p }
                                }
                            }
                        }

                        Picker("Type", selection: $debtType) {
                            Text("Owed to me").tag(DebtType.owedToMe)
                            Text("I owe").tag(DebtType.iOwe)
                        }
                        .pickerStyle(.segmented)
                        .tint(.lentGreen)

                        HStack {
                            TextField("Person name", text: $personName)
                                .textFieldStyle(.roundedBorder)
                                .foregroundColor(.white)
                                .autocapitalization(.words)
                            Button("New") {
                                showAddPerson = true
                            }
                            .foregroundColor(.lentGreen)
                        }

                        HStack {
                            TextField("Amount", value: $amount, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .foregroundColor(.white)
                            Picker("", selection: $currency) {
                                Text("₽").tag("₽")
                                Text("$").tag("$")
                                Text("€").tag("€")
                            }
                            .pickerStyle(.menu)
                            .tint(.lentGreen)
                        }

                        DatePicker("Debt date", selection: $date, displayedComponents: .date)
                            .tint(.lentGreen)
                            .foregroundColor(.white)

                        Toggle("Set due date", isOn: $hasDueDate)
                            .tint(.lentGreen)
                            .foregroundColor(.white)

                        if hasDueDate {
                            DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                                .tint(.lentGreen)
                                .foregroundColor(.white)
                        }

                        TextField("Description (optional)", text: $descriptionText)
                            .textFieldStyle(.roundedBorder)
                            .foregroundColor(.white)

                        TextField("Tags (comma-separated)", text: $tagsString)
                            .textFieldStyle(.roundedBorder)
                            .foregroundColor(.white)

                        if !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        Text(tag)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(LinearGradient.lentCardGradient)
                                            )
                                            .foregroundColor(.lentGreen)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .foregroundColor(.gray)
                                .font(.caption)
                            TextEditor(text: $notes)
                                .frame(height: 80)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(LinearGradient.lentCardGradient)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.lentGreen.opacity(0.12), lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }

                        if isEditing {
                            Picker("Status", selection: $status) {
                                ForEach(DebtStatus.allCases, id: \.self) { s in
                                    Text(s.rawValue).tag(s)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.lentGreen)
                            .foregroundColor(.white)
                        }

                        HStack(spacing: 12) {
                            Button("Cancel") {
                                dismiss()
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.lentGreen)

                            Button("Save") {
                                save()
                                dismiss()
                            }
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
                            .lentSoftShadow()
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "Edit debt" : "New debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.lentBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarTitleDisplayMode(.inline)
            .foregroundStyle(Color.lentGreen)
            .onAppear { fillFromDebtIfEditing() }
            .sheet(isPresented: $showAddPerson) {
                                AddPersonSheet(viewModel: viewModel, personName: $personName)
            }
        }
    }

    private func fillFromDebtIfEditing() {
        guard case .edit(let debt) = mode else { return }
        debtType = debt.type
        personName = debt.personName
        amount = debt.amount
        remainingAmount = debt.remainingAmount
        currency = debt.currency
        date = debt.date
        hasDueDate = debt.dueDate != nil
        dueDate = debt.dueDate ?? Date()
        descriptionText = debt.description ?? ""
        tagsString = debt.tags.joined(separator: ", ")
        notes = debt.notes
        status = debt.status
    }

    private func save() {
        let trimmedName = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, amount >= 0 else { return }

        var personId: UUID
        if let existing = viewModel.people.first(where: { $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }) {
            personId = existing.id
        } else {
            let newPerson = Person(id: UUID(), name: trimmedName, phone: nil, email: nil)
            viewModel.addPerson(newPerson)
            personId = newPerson.id
        }

        switch mode {
        case .add:
            let debt = Debt(
                personId: personId,
                personName: trimmedName,
                type: debtType,
                amount: amount,
                remainingAmount: amount,
                currency: currency,
                description: descriptionText.isEmpty ? nil : descriptionText,
                date: date,
                dueDate: hasDueDate ? dueDate : nil,
                status: .active,
                tags: tags,
                notes: notes
            )
            viewModel.addDebt(debt)
        case .edit(let existing):
            var updated = existing
            updated.personId = personId
            updated.personName = trimmedName
            updated.type = debtType
            updated.amount = amount
            updated.remainingAmount = isEditing ? remainingAmount : amount
            updated.currency = currency
            updated.description = descriptionText.isEmpty ? nil : descriptionText
            updated.date = date
            updated.dueDate = hasDueDate ? dueDate : nil
            updated.status = status
            updated.tags = tags
            updated.notes = notes
            viewModel.updateDebt(updated)
        }
    }
}

struct AddPersonSheet: View {
    @ObservedObject var viewModel: LentGreenViewModel
    @Binding var personName: String
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.lentBackgroundGradient.ignoresSafeArea()
                Form {
                    TextField("Name", text: $name)
                    TextField("Phone (optional)", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.lentBackground, for: .navigationBar)
            .foregroundStyle(Color.lentGreen)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.lentGreen)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            let person = Person(id: UUID(), name: trimmed, phone: phone.isEmpty ? nil : phone, email: email.isEmpty ? nil : email)
                            viewModel.addPerson(person)
                            personName = trimmed
                        }
                        dismiss()
                    }
                    .foregroundColor(.lentGreen)
                }
            }
            .onAppear { name = personName }
        }
    }
}

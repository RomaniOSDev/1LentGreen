//
//  PeopleView.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI

struct PeopleView: View {
    @ObservedObject var viewModel: LentGreenViewModel
    @State private var showAddPerson = false
    @State private var selectedPerson: Person?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.lentBackgroundGradient.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.people) { person in
                            PersonRowView(
                                person: person,
                                debtsCount: viewModel.debts(for: person.id).count,
                                totalAmount: viewModel.totalForPerson(person.id),
                                debts: viewModel.debts(for: person.id)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPerson = person
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.lentBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .foregroundStyle(Color.lentGreen)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddPerson = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.lentGreen)
                    }
                }
            }
            .sheet(isPresented: $showAddPerson) {
                AddPersonSheet(viewModel: viewModel, personName: .constant(""))
            }
            .navigationDestination(item: $selectedPerson) { person in
                PersonDebtsView(viewModel: viewModel, person: person)
            }
        }
    }
}

struct PersonRowView: View {
    let person: Person
    let debtsCount: Int
    let totalAmount: Double
    let debts: [Debt]

    var body: some View {
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
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(Color.lentGreen.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                Text(person.avatarLetter)
                    .foregroundColor(.lentGreen)
                    .font(.title2)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .foregroundColor(.white)
                    .font(.headline)
                Text("\(debtsCount) debt\(debtsCount == 1 ? "" : "s") • \(Int(totalAmount)) ₽")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.lentGreen)
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

struct PersonDebtsView: View {
    @ObservedObject var viewModel: LentGreenViewModel
    let person: Person
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDebt: Debt?
    @State private var showEditPerson = false
    @State private var showDeleteAlert = false

    private var currentPerson: Person {
        viewModel.people.first { $0.id == person.id } ?? person
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    private var personDebts: [Debt] {
        viewModel.debts(for: currentPerson.id).sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            LinearGradient.lentBackgroundGradient.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(personDebts) { debt in
                        DebtRowView(debt: debt, dateFormatter: dateFormatter)
                            .onTapGesture {
                                selectedDebt = debt
                            }
                    }
                }
                .padding()
            }
            .navigationTitle(currentPerson.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showEditPerson = true
                        } label: {
                            Label("Edit person", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete person", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.lentGreen)
                    }
                }
            }
            .navigationDestination(item: $selectedDebt) { debt in
                DebtDetailView(viewModel: viewModel, debt: debt)
            }
            .sheet(isPresented: $showEditPerson) {
                EditPersonSheet(viewModel: viewModel, person: currentPerson)
            }
            .alert("Delete person?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.deletePerson(currentPerson)
                    dismiss()
                }
            } message: {
                Text("\(currentPerson.name) and all related debts will be removed.")
            }
        }
    }
}

struct EditPersonSheet: View {
    @ObservedObject var viewModel: LentGreenViewModel
    let person: Person
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.lentBackground.ignoresSafeArea()
                Form {
                    TextField("Name", text: $name)
                    TextField("Phone (optional)", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit person")
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
                            var p = person
                            p.name = trimmed
                            p.phone = phone.isEmpty ? nil : phone
                            p.email = email.isEmpty ? nil : email
                            viewModel.updatePerson(p)
                        }
                        dismiss()
                    }
                    .foregroundColor(.lentGreen)
                }
            }
            .onAppear {
                name = person.name
                phone = person.phone ?? ""
                email = person.email ?? ""
            }
        }
    }
}

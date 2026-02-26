//
//  TemplatesListView.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI

struct TemplatesListView: View {
    @ObservedObject var viewModel: LentGreenViewModel
    @State private var showAddTemplate = false
    @State private var templateToEdit: DebtTemplate?

    var body: some View {
        ZStack {
            LinearGradient.lentBackgroundGradient.ignoresSafeArea()
            List {
                ForEach(viewModel.templates) { template in
                    TemplateRowView(template: template)
                        .listRowBackground(
                Rectangle()
                    .fill(LinearGradient.lentCardGradient)
            )
                        .listRowSeparatorTint(.gray)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            templateToEdit = template
                        }
                        .contextMenu {
                            Button {
                                templateToEdit = template
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                viewModel.deleteTemplate(template)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Templates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.lentBackground, for: .navigationBar)
        .foregroundStyle(Color.lentGreen)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    templateToEdit = nil
                    showAddTemplate = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.lentGreen)
                }
            }
        }
        .sheet(isPresented: $showAddTemplate) {
            TemplateEditSheet(viewModel: viewModel, template: nil)
        }
        .sheet(item: $templateToEdit) { template in
            TemplateEditSheet(viewModel: viewModel, template: template) {
                templateToEdit = nil
            }
        }
    }
}

struct TemplateRowView: View {
    let template: DebtTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .foregroundColor(.white)
                .font(.headline)
            HStack(spacing: 8) {
                Text(template.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.lentGreen)
                Text("•")
                    .foregroundColor(.gray)
                Text(template.currency)
                    .font(.caption)
                    .foregroundColor(.gray)
                if !template.tags.isEmpty {
                    Text("•")
                        .foregroundColor(.gray)
                    Text(template.tags.prefix(2).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TemplateEditSheet: View {
    @ObservedObject var viewModel: LentGreenViewModel
    let template: DebtTemplate?
    var onDismiss: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var personName: String = ""
    @State private var type: DebtType = .owedToMe
    @State private var currency: String = "₽"
    @State private var tagsString: String = ""

    private var tags: [String] {
        tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.lentBackgroundGradient.ignoresSafeArea()
                Form {
                    TextField("Template name", text: $name)
                    TextField("Default person (optional)", text: $personName)
                    Picker("Type", selection: $type) {
                        Text("Owed to me").tag(DebtType.owedToMe)
                        Text("I owe").tag(DebtType.iOwe)
                    }
                    .tint(.lentGreen)
                    Picker("Currency", selection: $currency) {
                        Text("₽").tag("₽")
                        Text("$").tag("$")
                        Text("€").tag("€")
                    }
                    .tint(.lentGreen)
                    TextField("Tags (comma-separated)", text: $tagsString)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(template == nil ? "New template" : "Edit template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.lentBackground, for: .navigationBar)
            .foregroundStyle(Color.lentGreen)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss?()
                        dismiss()
                    }
                    .foregroundColor(.lentGreen)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        onDismiss?()
                        dismiss()
                    }
                    .foregroundColor(.lentGreen)
                }
            }
            .onAppear {
                if let t = template {
                    name = t.name
                    personName = t.personName ?? ""
                    type = t.type
                    currency = t.currency
                    tagsString = t.tags.joined(separator: ", ")
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let person = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = template {
            var updated = existing
            updated.name = trimmed
            updated.personName = person.isEmpty ? nil : person
            updated.type = type
            updated.currency = currency
            updated.tags = tags
            viewModel.updateTemplate(updated)
        } else {
            let newTemplate = DebtTemplate(
                name: trimmed,
                personName: person.isEmpty ? nil : person,
                type: type,
                currency: currency,
                tags: tags
            )
            viewModel.addTemplate(newTemplate)
        }
    }
}

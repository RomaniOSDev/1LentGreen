//
//  LentGreenViewModel.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import Foundation
import Combine

final class LentGreenViewModel: ObservableObject {
    @Published var debts: [Debt] = []
    @Published var people: [Person] = []
    @Published var templates: [DebtTemplate] = []
    @Published var selectedFilter: FilterType = .all
    @Published var searchText: String = ""
    @Published var sortOrder: SortOrder = .dateDesc

    enum FilterType: String, CaseIterable {
        case all = "All"
        case active = "Active"
    }

    enum SortOrder: String, CaseIterable {
        case dateDesc = "Date (newest)"
        case dateAsc = "Date (oldest)"
        case amountDesc = "Amount (high)"
        case amountAsc = "Amount (low)"
        case person = "Person"
    }

    var filteredDebts: [Debt] {
        var result = debts
        switch selectedFilter {
        case .all:
            break
        case .active:
            result = result.filter { $0.status == .active || $0.status == .partiallyRepaid }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.personName.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) == true)
            }
        }
        switch sortOrder {
        case .dateDesc: return result.sorted { $0.date > $1.date }
        case .dateAsc: return result.sorted { $0.date < $1.date }
        case .amountDesc: return result.sorted { $0.remainingAmount > $1.remainingAmount }
        case .amountAsc: return result.sorted { $0.remainingAmount < $1.remainingAmount }
        case .person: return result.sorted { $0.personName.localizedCaseInsensitiveCompare($1.personName) == .orderedAscending }
        }
    }

    /// Recent people (with debts or recently used) for quick add
    var recentPeople: [Person] {
        let personIds = debts.prefix(50).map(\.personId)
        var seen = Set<UUID>()
        return personIds.compactMap { id in
            guard !seen.contains(id), let p = people.first(where: { $0.id == id }) else { return nil }
            seen.insert(id)
            return p
        }
    }

    var activeDebts: [Debt] {
        debts.filter { $0.status == .active || $0.status == .partiallyRepaid }
    }

    var repaidDebts: [Debt] {
        debts.filter { $0.status == .repaid }
    }

    var totalOwedToMe: Double {
        debts
            .filter { $0.type == .owedToMe && ($0.status == .active || $0.status == .partiallyRepaid) }
            .reduce(0) { $0 + $1.remainingAmount }
    }

    var totalIOwe: Double {
        debts
            .filter { $0.type == .iOwe && ($0.status == .active || $0.status == .partiallyRepaid) }
            .reduce(0) { $0 + $1.remainingAmount }
    }

    var netBalance: Double {
        totalOwedToMe - totalIOwe
    }

    var totalRepaid: Double {
        debts
            .filter { $0.status == .repaid }
            .reduce(0) { $0 + $1.amount }
    }

    func debts(for personId: UUID) -> [Debt] {
        debts.filter { $0.personId == personId }
    }

    func totalForPerson(_ personId: UUID) -> Double {
        debts(for: personId)
            .filter { $0.status == .active || $0.status == .partiallyRepaid }
            .reduce(0) { $0 + $1.remainingAmount }
    }

    /// Active debts with due date in the next N days (for Home "Due soon")
    func debtsDueSoon(withinDays days: Int = 7) -> [Debt] {
        let end = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return debts
            .filter { $0.status == .active || $0.status == .partiallyRepaid }
            .filter { guard let d = $0.dueDate else { return false }; return d >= Date() && d <= end }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    /// Most recent debts (for Home "Recent")
    func recentDebts(limit: Int = 5) -> [Debt] {
        Array(debts.sorted { $0.date > $1.date }.prefix(limit))
    }

    func addDebt(_ debt: Debt) {
        debts.append(debt)
        saveToUserDefaults()
        LentGreenNotificationService.scheduleReminder(for: debt)
    }

    func updateDebt(_ debt: Debt) {
        if let index = debts.firstIndex(where: { $0.id == debt.id }) {
            debts[index] = debt
            saveToUserDefaults()
            LentGreenNotificationService.scheduleReminder(for: debt)
        }
    }

    func deleteDebt(_ debt: Debt) {
        LentGreenNotificationService.cancelReminder(for: debt.id)
        debts.removeAll { $0.id == debt.id }
        saveToUserDefaults()
    }

    func markAsRepaid(_ debt: Debt, amount: Double? = nil) {
        guard let index = debts.firstIndex(where: { $0.id == debt.id }) else { return }
        if let repaymentAmount = amount, repaymentAmount < debts[index].remainingAmount {
            debts[index].remainingAmount -= repaymentAmount
            debts[index].status = .partiallyRepaid
        } else {
            debts[index].remainingAmount = 0
            debts[index].status = .repaid
        }
        saveToUserDefaults()
        LentGreenNotificationService.cancelReminder(for: debt.id)
    }

    func addPerson(_ person: Person) {
        people.append(person)
        saveToUserDefaults()
    }

    func updatePerson(_ person: Person) {
        if let index = people.firstIndex(where: { $0.id == person.id }) {
            people[index] = person
            for i in debts.indices where debts[i].personId == person.id {
                debts[i].personName = person.name
            }
            saveToUserDefaults()
        }
    }

    func deletePerson(_ person: Person) {
        people.removeAll { $0.id == person.id }
        debts.removeAll { $0.personId == person.id }
        saveToUserDefaults()
    }

    private let debtsKey = "lentgreen_debts"
    private let peopleKey = "lentgreen_people"
    private let templatesKey = "lentgreen_templates"

    func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(debts) {
            UserDefaults.standard.set(encoded, forKey: debtsKey)
        }
        if let encoded = try? JSONEncoder().encode(people) {
            UserDefaults.standard.set(encoded, forKey: peopleKey)
        }
        if let encoded = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(encoded, forKey: templatesKey)
        }
    }

    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: debtsKey),
           let decoded = try? JSONDecoder().decode([Debt].self, from: data) {
            debts = decoded
        }
        if let data = UserDefaults.standard.data(forKey: peopleKey),
           let decoded = try? JSONDecoder().decode([Person].self, from: data) {
            people = decoded
        }
        if let data = UserDefaults.standard.data(forKey: templatesKey),
           let decoded = try? JSONDecoder().decode([DebtTemplate].self, from: data) {
            templates = decoded
        }
        if debts.isEmpty && people.isEmpty {
            loadDemoData()
        }
        LentGreenNotificationService.rescheduleAll(debts: debts)
    }

    func resetAllData() {
        LentGreenNotificationService.rescheduleAll(debts: [])
        debts = []
        people = []
        templates = []
        saveToUserDefaults()
    }

    // MARK: - Templates
    func addTemplate(_ template: DebtTemplate) {
        templates.append(template)
        saveToUserDefaults()
    }

    func updateTemplate(_ template: DebtTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveToUserDefaults()
        }
    }

    func deleteTemplate(_ template: DebtTemplate) {
        templates.removeAll { $0.id == template.id }
        saveToUserDefaults()
    }

    // MARK: - Stats by period
    enum StatsPeriod: String, CaseIterable {
        case thisMonth = "This month"
        case last3Months = "Last 3 months"
        case thisYear = "This year"
        case all = "All time"
    }

    func debts(in period: StatsPeriod) -> [Debt] {
        let calendar = Calendar.current
        let now = Date()
        let start: Date? = switch period {
        case .thisMonth: calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        case .last3Months: calendar.date(byAdding: .month, value: -3, to: now)
        case .thisYear: calendar.date(from: calendar.dateComponents([.year], from: now))
        case .all: nil
        }
        guard let start else { return debts }
        return debts.filter { $0.date >= start }
    }

    func totalRepaid(in period: StatsPeriod) -> Double {
        debts(in: period)
            .filter { $0.status == .repaid }
            .reduce(0) { $0 + $1.amount }
    }

    func totalOwedToMe(in period: StatsPeriod) -> Double {
        debts(in: period)
            .filter { $0.type == .owedToMe && ($0.status == .active || $0.status == .partiallyRepaid) }
            .reduce(0) { $0 + $1.remainingAmount }
    }

    func totalIOwe(in period: StatsPeriod) -> Double {
        debts(in: period)
            .filter { $0.type == .iOwe && ($0.status == .active || $0.status == .partiallyRepaid) }
            .reduce(0) { $0 + $1.remainingAmount }
    }

    func breakdownByTag(in period: StatsPeriod) -> [(tag: String, amount: Double)] {
        var dict: [String: Double] = [:]
        for debt in debts(in: period) where debt.status != .repaid && debt.status != .writtenOff {
            let amount = debt.remainingAmount * (debt.type == .owedToMe ? 1 : -1)
            if debt.tags.isEmpty {
                dict["—", default: 0] += amount
            } else {
                for tag in debt.tags {
                    dict[tag, default: 0] += amount / Double(debt.tags.count)
                }
            }
        }
        return dict.map { ($0.key, $0.value) }.sorted { abs($0.1) > abs($1.1) }
    }

    struct TopPersonItem: Identifiable {
        let id: UUID
        let name: String
        let amount: Double
    }

    func topPeople(in period: StatsPeriod) -> [TopPersonItem] {
        var byPerson: [UUID: (name: String, amount: Double)] = [:]
        for debt in debts(in: period) where debt.status != .repaid && debt.status != .writtenOff {
            let sign = debt.type == .owedToMe ? 1.0 : -1.0
            let current = byPerson[debt.personId] ?? (debt.personName, 0)
            byPerson[debt.personId] = (current.name, current.amount + debt.remainingAmount * sign)
        }
        return byPerson.map { TopPersonItem(id: $0.key, name: $0.value.name, amount: abs($0.value.amount)) }
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0 }
    }

    private func loadDemoData() {
        let person1 = Person(id: UUID(), name: "Alex", phone: nil, email: nil)
        let person2 = Person(id: UUID(), name: "Maria", phone: nil, email: nil)
        let person3 = Person(id: UUID(), name: "Dmitry", phone: nil, email: nil)
        people = [person1, person2, person3]

        let debt1 = Debt(
            personId: person1.id,
            personName: person1.name,
            type: .owedToMe,
            amount: 5000,
            remainingAmount: 5000,
            currency: "₽",
            description: "Lunch",
            date: Date().addingTimeInterval(-86400 * 7),
            dueDate: Date().addingTimeInterval(86400 * 7),
            status: .active,
            tags: ["food", "friends"],
            notes: ""
        )
        let debt2 = Debt(
            personId: person2.id,
            personName: person2.name,
            type: .iOwe,
            amount: 3000,
            remainingAmount: 3000,
            currency: "₽",
            description: "Tickets",
            date: Date().addingTimeInterval(-86400 * 14),
            dueDate: nil,
            status: .active,
            tags: ["entertainment"],
            notes: ""
        )
        let debt3 = Debt(
            personId: person3.id,
            personName: person3.name,
            type: .owedToMe,
            amount: 2000,
            remainingAmount: 0,
            currency: "₽",
            description: "Coffee",
            date: Date().addingTimeInterval(-86400 * 30),
            dueDate: nil,
            status: .repaid,
            tags: ["food"],
            notes: ""
        )
        debts = [debt1, debt2, debt3]
    }
}

//
//  Models.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI

enum DebtType: String, CaseIterable, Codable {
    case owedToMe = "Owed to me"
    case iOwe = "I owe"

    var icon: String {
        switch self {
        case .owedToMe: return "arrow.down.circle.fill"
        case .iOwe: return "arrow.up.circle.fill"
        }
    }
}

enum DebtStatus: String, CaseIterable, Codable {
    case active = "Active"
    case repaid = "Repaid"
    case partiallyRepaid = "Partially repaid"
    case writtenOff = "Written off"

    var color: Color {
        switch self {
        case .repaid: return .lentGreen
        case .active, .partiallyRepaid, .writtenOff: return .gray
        }
    }
}

struct Person: Identifiable, Codable, Equatable, Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    var name: String
    var phone: String?
    var email: String?

    var avatarLetter: String {
        String(name.prefix(1)).uppercased()
    }
}

struct Debt: Identifiable, Codable, Hashable {
    static func == (lhs: Debt, rhs: Debt) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    var personId: UUID
    var personName: String
    var type: DebtType
    var amount: Double
    var remainingAmount: Double
    var currency: String
    var description: String?
    var date: Date
    var dueDate: Date?
    var status: DebtStatus
    var tags: [String]
    var notes: String
    let creationDate: Date

    init(
        id: UUID = UUID(),
        personId: UUID,
        personName: String,
        type: DebtType,
        amount: Double,
        remainingAmount: Double,
        currency: String = "₽",
        description: String? = nil,
        date: Date,
        dueDate: Date? = nil,
        status: DebtStatus,
        tags: [String] = [],
        notes: String = "",
        creationDate: Date = Date()
    ) {
        self.id = id
        self.personId = personId
        self.personName = personName
        self.type = type
        self.amount = amount
        self.remainingAmount = remainingAmount
        self.currency = currency
        self.description = description
        self.date = date
        self.dueDate = dueDate
        self.status = status
        self.tags = tags
        self.notes = notes
        self.creationDate = creationDate
    }

    var isFullyRepaid: Bool {
        remainingAmount == 0 || status == .repaid
    }

    var progress: Double {
        guard amount > 0 else { return 0 }
        return (amount - remainingAmount) / amount
    }
}

struct DebtTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var personName: String?
    var type: DebtType
    var currency: String
    var tags: [String]

    init(id: UUID = UUID(), name: String, personName: String? = nil, type: DebtType, currency: String = "₽", tags: [String] = []) {
        self.id = id
        self.name = name
        self.personName = personName
        self.type = type
        self.currency = currency
        self.tags = tags
    }
}

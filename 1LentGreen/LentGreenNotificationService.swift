//
//  LentGreenNotificationService.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import Foundation
import UserNotifications

enum LentGreenNotificationService {
    private static let remindersEnabledKey = "lentgreen_notifications"
    private static let debtPrefix = "lentgreen_debt_"

    static var areRemindersEnabled: Bool {
        UserDefaults.standard.bool(forKey: remindersEnabledKey)
    }

    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    static func scheduleReminder(for debt: Debt) {
        guard areRemindersEnabled else { return }
        guard let due = debt.dueDate, debt.status != .repaid, debt.status != .writtenOff else {
            cancelReminder(for: debt.id)
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "LentGreen"
        content.body = "Due: \(debt.personName) — \(Int(debt.remainingAmount)) \(debt.currency)"
        content.sound = .default

        let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: due) ?? due
        var components = Calendar.current.dateComponents([.year, .month, .day], from: dayBefore)
        components.hour = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: debtPrefix + debt.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelReminder(for debtId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [debtPrefix + debtId.uuidString])
    }

    static func rescheduleAll(debts: [Debt]) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix(debtPrefix) }.map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
            guard areRemindersEnabled else { return }
            for debt in debts where debt.dueDate != nil && debt.status != .repaid && debt.status != .writtenOff {
                scheduleReminder(for: debt)
            }
        }
    }
}

//
//  LentGreenComponents.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI

struct StatusPill: View {
    let status: DebtStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Group {
                    if status == .repaid {
                        LinearGradient.lentGreenGradient
                    } else {
                        LinearGradient.lentCardGradient
                    }
                }
            )
            .foregroundColor(status == .repaid ? .black : .lentGreen)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(status == .repaid ? Color.clear : Color.lentGreen.opacity(0.5), lineWidth: 1)
            )
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

struct StatCard: View {
    let title: String
    let amount: Double
    var icon: String = "dollarsign"
    var currency: String = "₽"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(LinearGradient.lentTitleGradient)
                Text(title)
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            Text("\(Int(amount)) \(currency)")
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = .white

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundStyle(LinearGradient.lentTitleGradient)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .foregroundColor(valueColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

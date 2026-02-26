//
//  SettingsView.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: LentGreenViewModel
    @AppStorage("lentgreen_default_currency") private var defaultCurrency: String = "₽"
    @AppStorage("lentgreen_notifications") private var notificationsEnabled: Bool = false
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.lentBackgroundGradient.ignoresSafeArea()
                Form {
                    Section {
                        Picker("Default currency", selection: $defaultCurrency) {
                            Text("₽").tag("₽")
                            Text("$").tag("$")
                            Text("€").tag("€")
                        }
                        .tint(.lentGreen)
                        Toggle("Due date reminders", isOn: $notificationsEnabled)
                            .tint(.lentGreen)
                            .onChange(of: notificationsEnabled) { _, enabled in
                                if enabled {
                                    LentGreenNotificationService.requestAuthorization { _ in
                                        LentGreenNotificationService.rescheduleAll(debts: viewModel.debts)
                                    }
                                } else {
                                    LentGreenNotificationService.rescheduleAll(debts: [])
                                }
                            }
                    } header: {
                        Text("General")
                            .foregroundColor(.lentGreen)
                    }

                    Section {
                        NavigationLink {
                            TemplatesListView(viewModel: viewModel)
                        } label: {
                            Label("Templates", systemImage: "doc.on.doc")
                                .foregroundColor(.lentGreen)
                        }
                    } header: {
                        Text("Templates")
                            .foregroundColor(.lentGreen)
                    }

                    Section {
                        Button {
                            AppActions.rateApp()
                        } label: {
                            Label("Rate us", systemImage: "star.fill")
                                .foregroundColor(.lentGreen)
                        }
                        Button {
                            AppActions.openPrivacyPolicy()
                        } label: {
                            Label("Privacy", systemImage: "hand.raised.fill")
                                .foregroundColor(.lentGreen)
                        }
                        Button {
                            AppActions.openTerms()
                        } label: {
                            Label("Terms", systemImage: "doc.text.fill")
                                .foregroundColor(.lentGreen)
                        }
                    } header: {
                        Text("About")
                            .foregroundColor(.lentGreen)
                    }

                    Section {
                        Button("Reset all data", role: .destructive) {
                            showResetAlert = true
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.lentBackground, for: .navigationBar)
            .foregroundStyle(Color.lentGreen)
            .alert("Reset all data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.resetAllData()
                }
            } message: {
                Text("All debts and people will be deleted. This cannot be undone.")
            }
        }
    }
}

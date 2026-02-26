//
//  ContentView.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView(onComplete: {
                    hasCompletedOnboarding = true
                })
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = LentGreenViewModel()

    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            DebtListView(viewModel: viewModel)
                .tabItem {
                    Label("Debts", systemImage: "list.bullet")
                }

            PeopleView(viewModel: viewModel)
                .tabItem {
                    Label("People", systemImage: "person.fill")
                }

            StatsView(viewModel: viewModel)
                .tabItem {
                    Label("Statistics", systemImage: "chart.pie.fill")
                }

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.lentGreen)
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.loadFromUserDefaults()
        }
    }
}

#Preview("Main") {
    ContentView()
}

#Preview("Onboarding") {
    OnboardingView(onComplete: {})
}

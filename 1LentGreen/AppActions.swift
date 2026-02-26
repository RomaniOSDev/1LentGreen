//
//  AppActions.swift
//  1LentGreen
//
//  Created by Harry Wasser on 21.02.2026.
//

import UIKit
import StoreKit

enum AppActions {
    private static let privacyURLString = "https://www.termsfeed.com/live/4614beff-eca6-43f9-b142-330eeadf7772"
    private static let termsURLString = "https://www.termsfeed.com/live/317603f9-71c0-4bd7-9a5e-e88bcce16739"

    static func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    static func openPrivacyPolicy() {
        if let url = URL(string: privacyURLString) {
            UIApplication.shared.open(url)
        }
    }

    static func openTerms() {
        if let url = URL(string: termsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

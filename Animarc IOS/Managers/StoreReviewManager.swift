//
//  StoreReviewManager.swift
//  Animarc IOS
//
//  Manager for handling App Store review requests
//

import Foundation
import StoreKit
import UIKit

@MainActor
class StoreReviewManager: ObservableObject {
    static let shared = StoreReviewManager()
    
    private init() {}
    
    /// Request App Store review using StoreKit
    /// Note: iOS controls when the review prompt actually appears
    /// This method requests it, but iOS may defer it based on user's review history
    func requestReview() {
        // Get the current window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}


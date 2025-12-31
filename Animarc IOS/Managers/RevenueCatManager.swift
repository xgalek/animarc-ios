//
//  RevenueCatManager.swift
//  Animarc IOS
//
//  RevenueCat subscription management
//

import Foundation
import RevenueCat
import StoreKit
import SwiftUI
import UIKit

final class RevenueCatManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    @MainActor static let shared = RevenueCatManager()
    
    // MARK: - Published Properties
    @Published var customerInfo: CustomerInfo?
    @Published var offerings: Offerings?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Configuration
    private let apiKey: String = "appl_OCBzZIPDsWduwvkbMGWGizCBIzF"
    
    // MARK: - Entitlement Identifier
    let proEntitlementIdentifier = "Animarc Pro"
    
    // MARK: - Initialization
    override init() {
        super.init()
        Task { @MainActor in
            configureRevenueCat()
        }
    }
    
    // MARK: - Configuration
    private func configureRevenueCat() {
        Purchases.logLevel = .info // Production log level
        
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: apiKey)
                .with(usesStoreKit2IfAvailable: true)
                .build()
        )
        
        // Set delegate for customer info updates
        Purchases.shared.delegate = self
        
        // Load initial customer info
        Task {
            await loadCustomerInfo()
            await loadOfferings()
        }
    }
    
    // MARK: - Customer Info
    @MainActor
    func loadCustomerInfo() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let info = try await Purchases.shared.customerInfo()
            self.customerInfo = info
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load subscription info: \(error.localizedDescription)"
            self.isLoading = false
            print("RevenueCat Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Offerings
    @MainActor
    func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
        } catch {
            print("RevenueCat Offerings Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Entitlement Checking
    @MainActor
    var isPro: Bool {
        guard let customerInfo = customerInfo else { return false }
        return customerInfo.entitlements[proEntitlementIdentifier]?.isActive == true
    }
    
    @MainActor
    var isProOrInTrial: Bool {
        guard let customerInfo = customerInfo else { return false }
        let entitlement = customerInfo.entitlements[proEntitlementIdentifier]
        return entitlement?.isActive == true || entitlement?.willRenew == true
    }
    
    // MARK: - Purchase
    @MainActor
    func purchase(package: Package) async throws -> CustomerInfo {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let (transaction, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)
            
            if userCancelled {
                throw RevenueCatError.userCancelled
            }
            
            self.customerInfo = customerInfo
            
            return customerInfo
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    @MainActor
    func restorePurchases() async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerInfo = customerInfo
        } catch {
            self.errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Customer Center
    @MainActor
    func presentCustomerCenter() {
        // Use StoreKit 2 API if available (iOS 15+)
        if #available(iOS 15.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                Task { @MainActor in
                    do {
                        try await AppStore.showManageSubscriptions(in: windowScene)
                    } catch {
                        print("StoreKit subscription management error: \(error.localizedDescription)")
                        // Fallback to URL if StoreKit fails
                        self.openSubscriptionURL()
                    }
                }
            } else {
                // Fallback to URL if window scene not available
                openSubscriptionURL()
            }
        } else {
            // Fallback to URL for older iOS versions
            openSubscriptionURL()
        }
    }
    
    @MainActor
    private func openSubscriptionURL() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        } else {
            self.errorMessage = "Unable to open subscription management"
        }
    }
    
    // MARK: - User Identification
    @MainActor
    func identifyUser(userId: String) async throws {
        do {
            let (customerInfo, created) = try await Purchases.shared.logIn(userId)
            self.customerInfo = customerInfo
            print("RevenueCat: User \(created ? "created" : "logged in"): \(userId)")
        } catch {
            print("RevenueCat Login Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func logout() async throws {
        do {
            let customerInfo = try await Purchases.shared.logOut()
            self.customerInfo = customerInfo
        } catch {
            print("RevenueCat Logout Error: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - PurchasesDelegate
extension RevenueCatManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
        }
    }
}

// MARK: - Custom Errors
enum RevenueCatError: LocalizedError {
    case userCancelled
    case purchaseFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled"
        case .purchaseFailed(let message):
            return message
        }
    }
}




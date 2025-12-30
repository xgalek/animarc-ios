//
//  PaywallView.swift
//  Animarc IOS
//
//  RevenueCat Paywall
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @StateObject private var revenueCat = RevenueCatManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedPackage: Package?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isPurchasing = false
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Unlock Animarc Pro")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Level up your focus journey")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                    .padding(.top, 40)
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "sparkles", title: "Unlimited Focus Sessions", description: "No daily limits")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", description: "Track your progress")
                        FeatureRow(icon: "crown.fill", title: "Premium Ranks", description: "Unlock exclusive ranks")
                        FeatureRow(icon: "gift.fill", title: "Exclusive Items", description: "Rare portal items")
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    // Packages
                    if let offerings = revenueCat.offerings,
                       let currentOffering = offerings.current {
                        VStack(spacing: 12) {
                            ForEach(currentOffering.availablePackages, id: \.identifier) { package in
                                PackageButton(
                                    package: package,
                                    isSelected: selectedPackage?.identifier == package.identifier,
                                    onSelect: {
                                        selectedPackage = package
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                    } else {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 40)
                    }
                    
                    // Purchase Button
                    Button(action: {
                        purchaseSelectedPackage()
                    }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Start Free Trial")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedPackage != nil ? Color(hex: "#4ADE80") : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(selectedPackage == nil || isPurchasing)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    // Restore Purchases
                    Button(action: {
                        restorePurchases()
                    }) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                    .padding(.top, 8)
                    
                    // Terms & Privacy
                    HStack(spacing: 16) {
                        Link("Terms of Service", destination: URL(string: "https://your-terms-url.com")!)
                        Text("•")
                            .foregroundColor(Color(hex: "#9CA3AF"))
                        Link("Privacy Policy", destination: URL(string: "https://your-privacy-url.com")!)
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            Task {
                await revenueCat.loadOfferings()
                // Auto-select monthly package
                if let offerings = revenueCat.offerings,
                   let currentOffering = offerings.current,
                   let monthlyPackage = currentOffering.availablePackages.first(where: { $0.storeProduct.subscriptionPeriod?.unit == .month }) {
                    selectedPackage = monthlyPackage
                }
            }
        }
    }
    
    private func purchaseSelectedPackage() {
        guard let package = selectedPackage else { return }
        
        isPurchasing = true
        
        Task {
            do {
                let customerInfo = try await revenueCat.purchase(package: package)
                
                // Check if purchase was successful
                if customerInfo.entitlements[revenueCat.proEntitlementIdentifier]?.isActive == true {
                    await MainActor.run {
                        isPurchasing = false
                        dismiss()
                    }
                } else {
                    await MainActor.run {
                        isPurchasing = false
                        errorMessage = "Purchase completed but entitlement not active"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    // Check if it's a user cancelled error
                    if let rcError = error as? RevenueCatError {
                        if case .userCancelled = rcError {
                            // User cancelled - don't show error
                            return
                        }
                    }
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                try await revenueCat.restorePurchases()
                if revenueCat.isPro {
                    await MainActor.run {
                        dismiss()
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "No active subscriptions found"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#4ADE80"))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
            
            Spacer()
        }
    }
}

// MARK: - Package Button
struct PackageButton: View {
    let package: Package
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var packageTitle: String {
        switch package.packageType {
        case .monthly:
            return "Monthly"
        case .annual:
            return "Yearly"
        case .lifetime:
            return "Lifetime"
        default:
            return package.storeProduct.localizedTitle
        }
    }
    
    private var packageSubtitle: String {
        if package.packageType == .annual {
            return "Save 17%"
        }
        return ""
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(packageTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if !packageSubtitle.isEmpty {
                            Text(packageSubtitle)
                                .font(.caption)
                                .foregroundColor(Color(hex: "#4ADE80"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#4ADE80").opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    
                    Text(package.storeProduct.localizedPriceString)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(hex: "#4ADE80") : Color(hex: "#9CA3AF"))
            }
            .padding(16)
            .background(isSelected ? Color(hex: "#4ADE80").opacity(0.1) : Color(hex: "#2A3441"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "#4ADE80") : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Extension for Price String
extension StoreProduct {
    var localizedPriceString: String {
        // Format the price using Decimal to NSDecimalNumber conversion
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        let priceNumber = NSDecimalNumber(decimal: price)
        return formatter.string(from: priceNumber) ?? "$0.00"
    }
}



//
//  PaywallView.swift
//  Animarc IOS
//
//  RevenueCat Paywall Editor Paywall
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct PaywallView: View {
    @StateObject private var revenueCat = RevenueCatManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Group {
            if let offering = revenueCat.offerings?.current {
                RevenueCatUI.PaywallView(offering: offering)
                    .onPurchaseCompleted { customerInfo in
                        // Update customer info after purchase
                        Task { @MainActor in
                            await revenueCat.loadCustomerInfo()
                            if revenueCat.isPro {
                                dismiss()
                            }
                        }
                    }
                    .onRestoreCompleted { customerInfo in
                        // Update customer info after restore
                        Task { @MainActor in
                            await revenueCat.loadCustomerInfo()
                            if revenueCat.isPro {
                                dismiss()
                            }
                        }
                    }
            } else {
                // Loading state
                ZStack {
                    Color(hex: "#1A2332")
                        .ignoresSafeArea()
                    
                    VStack {
                        ProgressView()
                            .tint(.white)
                        Text("Loading subscription options...")
                            .foregroundColor(.white)
                            .padding(.top, 16)
                    }
                }
                .onAppear {
                    Task {
                        await revenueCat.loadOfferings()
                    }
                }
            }
        }
    }
}

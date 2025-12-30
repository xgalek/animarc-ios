//
//  CustomerCenterView.swift
//  Animarc IOS
//
//  Customer Center wrapper
//

import SwiftUI
import RevenueCat

struct CustomerCenterView: View {
    @StateObject private var revenueCat = RevenueCatManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Manage Subscription")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                Text("Manage your subscription, restore purchases, or view your subscription status.")
                    .font(.body)
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Spacer()
                
                Button(action: {
                    revenueCat.presentCustomerCenter()
                }) {
                    Text("Open Customer Center")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#4ADE80"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                
                // Current subscription status
                if let customerInfo = revenueCat.customerInfo {
                    VStack(spacing: 12) {
                        Text("Current Status")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if revenueCat.isPro {
                            Text("✅ Animarc Pro Active")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#4ADE80"))
                        } else {
                            Text("Free Plan")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                        }
                    }
                    .padding()
                    .background(Color(hex: "#2A3441"))
                    .cornerRadius(12)
                    .padding(.horizontal, 30)
                }
                
                Spacer()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}



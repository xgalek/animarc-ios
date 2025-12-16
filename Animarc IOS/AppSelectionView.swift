//
//  AppSelectionView.swift
//  Animarc IOS
//
//  View for selecting apps to block during focus sessions
//
//  TEMPORARILY DISABLED: Commented out pending Apple's approval of Family Controls entitlement.
//  This code will be re-enabled once the entitlement is approved.
//

/*
import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @StateObject private var appBlockingManager = AppBlockingManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var showLimitAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "#1A2332")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "#6B46C1"))
                        
                        Text("Select Apps to Block")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Choose which apps to block during focus sessions. Phone and Messages will always remain accessible.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.top, 40)
                    
                    // Current selection info
                    if !appBlockingManager.blockedApplications.isEmpty {
                        VStack(spacing: 8) {
                            Text("Currently blocking \(appBlockingManager.blockedApplications.count) app\(appBlockingManager.blockedApplications.count == 1 ? "" : "s")")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("All other apps will be blocked during focus sessions")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                        }
                        .padding()
                        .background(Color(hex: "#374151"))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "#6B46C1"))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("How it works:")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text("• Select apps you want to block during focus sessions")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                
                                Text("• Phone and Messages remain accessible automatically")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                
                                Text("• All other apps will be blocked")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                            }
                        }
                        .padding()
                        .background(Color(hex: "#374151"))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showPicker = true
                        }) {
                            Text("Select Apps")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#6B46C1"))
                                .cornerRadius(25)
                                .shadow(color: Color(hex: "#6B46C1").opacity(0.6), radius: 15, x: 0, y: 0)
                        }
                        .padding(.horizontal, 30)
                        
                        Button(action: {
                            saveSelection()
                        }) {
                            Text("Save")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#22C55E"))
                                .cornerRadius(25)
                        }
                        .padding(.horizontal, 30)
                        .disabled(appBlockingManager.blockedApplications.isEmpty)
                        
                        Button(action: {
                            clearSelection()
                        }) {
                            Text("Clear Selection")
                                .font(.headline)
                                .foregroundColor(Color(hex: "#DC2626"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("App Blocking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .familyActivityPicker(isPresented: $showPicker, selection: $selection)
            .onChange(of: selection) { _, newSelection in
                // Update selection when user picks apps
                handleSelectionChange(newSelection)
            }
            .alert("Selection Updated", isPresented: $showLimitAlert) {
                Button("OK") {}
            } message: {
                Text("Your app blocking selection has been updated.")
            }
        }
    }
    
    private func handleSelectionChange(_ newSelection: FamilyActivitySelection) {
        // Convert FamilyActivitySelection to ApplicationToken set
        let applicationTokens = newSelection.applicationTokens
        
        // Note: Screen Time API doesn't have a direct way to "block all except these"
        // So we store the selected apps as apps to block
        // The system will automatically allow Phone and Messages
        appBlockingManager.setBlockedApplications(applicationTokens)
    }
    
    private func saveSelection() {
        // Selection is already saved via handleSelectionChange
        // Just dismiss
        dismiss()
    }
    
    private func clearSelection() {
        appBlockingManager.setBlockedApplications([])
        selection = FamilyActivitySelection()
    }
}

#Preview {
    AppSelectionView()
}
*/

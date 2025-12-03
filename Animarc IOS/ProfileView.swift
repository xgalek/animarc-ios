//
//  ProfileView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

struct ProfileView: View {
    @Binding var navigationPath: NavigationPath
    @Environment(\.dismiss) var dismiss
    @State private var notificationsEnabled = true
    @State private var soundsEnabled = true
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Top Section - Profile Card
                    VStack(spacing: 16) {
                        // Circular avatar
                        Circle()
                            .fill(Color(hex: "#A770FF"))
                            .frame(width: 100, height: 100)
                            .shadow(color: Color(hex: "#A770FF").opacity(0.5), radius: 15, x: 0, y: 0)
                        
                        // Username
                        Text("Hunter")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Rank and Level
                        HStack(spacing: 12) {
                            Text("E-Rank")
                                .font(.headline)
                                .foregroundColor(Color(hex: "#FF9500"))
                            
                            Text("•")
                                .font(.headline)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                            
                            Text("Level 13")
                                .font(.headline)
                                .foregroundColor(Color(hex: "#A770FF"))
                        }
                        
                        // XP Progress Bar
                        VStack(spacing: 8) {
                            HStack {
                                Text("2322 / 2500 XP")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                Spacer()
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: "#9CA3AF").opacity(0.3))
                                        .frame(height: 12)
                                    
                                    // Progress fill
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: "#22C55E"))
                                        .frame(width: geometry.size.width * (2322.0 / 2500.0), height: 12)
                                }
                            }
                            .frame(height: 12)
                        }
                        .padding(.horizontal, 20)
                        
                        // Streak
                        HStack(spacing: 6) {
                            Text("🔥")
                                .font(.system(size: 20))
                            Text("3 day streak")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 20)
                    .background(Color(hex: "#374151"))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Middle Section - Quick Stats Grid
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            // Total Focus Time
                            StatCard(
                                icon: "clock.fill",
                                label: "Total Focus Time",
                                value: "24h 30m"
                            )
                            
                            // Sessions Today
                            StatCard(
                                icon: "flame.fill",
                                label: "Sessions Today",
                                value: "3"
                            )
                        }
                        
                        HStack(spacing: 16) {
                            // Current Streak
                            StatCard(
                                icon: "calendar",
                                label: "Current Streak",
                                value: "3 days"
                            )
                            
                            // Achievements
                            StatCard(
                                icon: "trophy.fill",
                                label: "Achievements",
                                value: "12 earned"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Bottom Section - Settings
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Settings")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            // Notifications Toggle
                            SettingsRow(
                                icon: "bell.fill",
                                title: "Notifications",
                                toggle: $notificationsEnabled
                            )
                            
                            Divider()
                                .background(Color(hex: "#9CA3AF").opacity(0.3))
                                .padding(.leading, 60)
                            
                            // Sounds Toggle
                            SettingsRow(
                                icon: "speaker.wave.2.fill",
                                title: "Sounds",
                                toggle: $soundsEnabled
                            )
                        }
                        .background(Color(hex: "#374151"))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        
                        // Future buttons placeholder
                        VStack(spacing: 12) {
                            Button(action: {
                                // About action - placeholder
                            }) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                    Text("About")
                                        .font(.body)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#374151"))
                                .cornerRadius(15)
                            }
                            
                            Button(action: {
                                // Help action - placeholder
                            }) {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                    Text("Help")
                                        .font(.body)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#374151"))
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            
            // Top Navigation Bar
            VStack {
                HStack {
                    // Back button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// Stat Card Component
struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#A770FF"))
            
            Text(label)
                .font(.caption)
                .foregroundColor(Color(hex: "#9CA3AF"))
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(hex: "#374151"))
        .cornerRadius(15)
    }
}

// Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String
    @Binding var toggle: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#9CA3AF"))
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $toggle)
                .labelsHidden()
                .tint(Color(hex: "#6B46C1"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    NavigationStack {
        ProfileView(navigationPath: .constant(NavigationPath()))
    }
}


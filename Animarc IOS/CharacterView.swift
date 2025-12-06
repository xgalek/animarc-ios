//
//  CharacterView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

struct InventoryItem: Identifiable {
    let id = UUID()
    let icon: String
    let name: String
    let isEmpty: Bool
}

struct CharacterView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @State private var showProfile = false
    @State private var showChallengeAlert = false
    @State private var selectedItem: InventoryItem?
    @State private var showStatAllocation = false
    
    // Stat allocation system
    @State private var availablePoints: Int = 5
    @State private var tempStats: [String: Int] = [
        "HP": 150,
        "STR": 27,
        "AGI": 31,
        "INT": 21,
        "VIT": 19
    ]
    @State private var workingStats: [String: Int] = [:]
    @State private var originalStats: [String: Int] = [:]
    private let minStatValue = 10
    
    // Dummy inventory data
    @State private var inventoryItems: [InventoryItem] = [
        InventoryItem(icon: "⚔️", name: "Iron Sword", isEmpty: false),
        InventoryItem(icon: "🛡️", name: "Wood Shield", isEmpty: false),
        InventoryItem(icon: "", name: "", isEmpty: true),
        InventoryItem(icon: "", name: "", isEmpty: true),
        InventoryItem(icon: "", name: "", isEmpty: true),
        InventoryItem(icon: "", name: "", isEmpty: true),
        InventoryItem(icon: "", name: "", isEmpty: true),
        InventoryItem(icon: "", name: "", isEmpty: true)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "#1A2332")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Card Section - Character & Stats
                        VStack(spacing: 16) {
                            // Top: Character Sprite and Stats (HStack)
                            HStack(alignment: .top, spacing: 16) {
                                // Left Side: Character Avatar
                                Circle()
                                    .fill(progressManager.currentRankInfo.swiftUIColor)
                                    .frame(width: 150, height: 150)
                                    .shadow(color: progressManager.currentRankInfo.swiftUIColor.opacity(0.5), radius: 15, x: 0, y: 0)
                                
                                // Right Side: Stats Display
                                VStack(alignment: .leading, spacing: 6) {
                                    // Username
                                    Text(progressManager.userProgress?.displayName ?? "Hunter")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    // Read-only stats
                                    Text("❤️ HP: \(tempStats["HP"] ?? 150)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Text("⚔️ STR: \(tempStats["STR"] ?? 27)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Text("⚡ AGI: \(tempStats["AGI"] ?? 31)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Text("🧠 INT: \(tempStats["INT"] ?? 21)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Text("🛡️ VIT: \(tempStats["VIT"] ?? 19)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    // Points Available and Allocate Button (only if points > 0)
                                    if availablePoints > 0 {
                                        Text("📊 \(availablePoints) Points Available")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                            .padding(.top, 4)
                                        
                                        Button(action: {
                                            originalStats = tempStats
                                            workingStats = tempStats
                                            showStatAllocation = true
                                        }) {
                                            Text("ALLOCATE POINTS")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                .background(Color(hex: "#6B46C1"))
                                                .cornerRadius(8)
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 20)
                        .background(Color(hex: "#374151"))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Below Card: Level, Rank, Streak (Horizontal)
                        HStack(spacing: 12) {
                            Text("Level \(progressManager.currentLevel)")
                                .font(.headline)
                                .foregroundColor(Color(hex: "#A770FF"))
                            
                            Text("|")
                                .font(.headline)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                            
                            Text("\(progressManager.currentRank)-Rank")
                                .font(.headline)
                                .foregroundColor(progressManager.currentRankInfo.swiftUIColor)
                            
                            Text("|")
                                .font(.headline)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                            
                            HStack(spacing: 4) {
                                Text("🔥")
                                    .font(.system(size: 16))
                                Text("\(progressManager.currentStreak) streak")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Rank Title
                        Text(progressManager.currentRankInfo.title)
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                        
                        // XP Progress Bar
                        VStack(spacing: 8) {
                            HStack {
                                Text(progressManager.levelProgress.progressText)
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                Spacer()
                                Text("\(Int(progressManager.levelProgress.progressPercent))%")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#9CA3AF"))
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
                                        .frame(width: geometry.size.width * (progressManager.levelProgress.progressPercent / 100.0), height: 12)
                                }
                            }
                            .frame(height: 12)
                        }
                        .padding(.horizontal, 20)
                        
                        // Inventory Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("INVENTORY")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(inventoryItems) { item in
                                    InventorySlot(item: item)
                                        .onTapGesture {
                                            selectedItem = item
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Challenge Button
                        Button(action: {
                            showChallengeAlert = true
                        }) {
                            Text("⚔️ CHALLENGE HUNTERS")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#6B46C1"))
                                .cornerRadius(25)
                                .shadow(color: Color(hex: "#6B46C1").opacity(0.6), radius: 15, x: 0, y: 0)
                                .shadow(color: Color(hex: "#4A90E2").opacity(0.4), radius: 25, x: 0, y: 0)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AvatarButton(showProfile: $showProfile)
                }
            }
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    ProfileView(navigationPath: .constant(NavigationPath()))
                        .environmentObject(progressManager)
                }
            }
            .alert("Coming Soon!", isPresented: $showChallengeAlert) {
                Button("OK", role: .cancel) { }
            }
            .alert(item: $selectedItem) { item in
                Alert(
                    title: Text(item.isEmpty ? "Empty Slot" : item.name),
                    message: Text(item.isEmpty ? "This slot is empty" : "You have \(item.name)"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showStatAllocation) {
                StatAllocationSheet(
                    workingStats: $workingStats,
                    availablePoints: $availablePoints,
                    originalStats: originalStats,
                    isPresented: $showStatAllocation,
                    onSave: { savedStats in
                        tempStats = savedStats
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

struct StatAllocationSheet: View {
    @Binding var workingStats: [String: Int]
    @Binding var availablePoints: Int
    let originalStats: [String: Int]
    @Binding var isPresented: Bool
    let onSave: ([String: Int]) -> Void
    
    @State private var tempAvailablePoints: Int = 0
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Top bar with title and X button
                HStack {
                    Text("ALLOCATE STAT POINTS")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color(hex: "#374151"))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Divider()
                    .background(Color(hex: "#9CA3AF").opacity(0.3))
                
                // Available Points Display
                Text("Available Points: \(tempAvailablePoints)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                // Stats with controls
                VStack(spacing: 16) {
                    StatRowWithControls(
                        icon: "⚔️",
                        label: "STR",
                        value: Binding(
                            get: { workingStats["STR"] ?? 27 },
                            set: { workingStats["STR"] = $0 }
                        ),
                        originalValue: originalStats["STR"] ?? 27,
                        availablePoints: $tempAvailablePoints
                    )
                    
                    StatRowWithControls(
                        icon: "⚡",
                        label: "AGI",
                        value: Binding(
                            get: { workingStats["AGI"] ?? 31 },
                            set: { workingStats["AGI"] = $0 }
                        ),
                        originalValue: originalStats["AGI"] ?? 31,
                        availablePoints: $tempAvailablePoints
                    )
                    
                    StatRowWithControls(
                        icon: "🧠",
                        label: "INT",
                        value: Binding(
                            get: { workingStats["INT"] ?? 21 },
                            set: { workingStats["INT"] = $0 }
                        ),
                        originalValue: originalStats["INT"] ?? 21,
                        availablePoints: $tempAvailablePoints
                    )
                    
                    StatRowWithControls(
                        icon: "🛡️",
                        label: "VIT",
                        value: Binding(
                            get: { workingStats["VIT"] ?? 19 },
                            set: { workingStats["VIT"] = $0 }
                        ),
                        originalValue: originalStats["VIT"] ?? 19,
                        availablePoints: $tempAvailablePoints
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Save Changes Button
                Button(action: {
                    availablePoints = tempAvailablePoints
                    onSave(workingStats)
                    isPresented = false
                }) {
                    Text("SAVE CHANGES")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#6B46C1"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            tempAvailablePoints = availablePoints
        }
    }
}

struct StatRowWithControls: View {
    let icon: String
    let label: String
    @Binding var value: Int
    let originalValue: Int
    @Binding var availablePoints: Int
    
    var canDecrement: Bool {
        value > originalValue
    }
    
    var canIncrement: Bool {
        availablePoints > 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(icon) \(label): \(value)")
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            // Decrement button
            Button(action: {
                if canDecrement {
                    value -= 1
                    availablePoints += 1
                }
            }) {
                Text("-")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "#374151"))
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#9CA3AF"), lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .disabled(!canDecrement)
            .opacity(canDecrement ? 1.0 : 0.5)
            
            // Increment button
            Button(action: {
                if canIncrement {
                    value += 1
                    availablePoints -= 1
                }
            }) {
                Text("+")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "#374151"))
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#9CA3AF"), lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .disabled(!canIncrement)
            .opacity(canIncrement ? 1.0 : 0.5)
        }
    }
}

struct InventorySlot: View {
    let item: InventoryItem
    
    var body: some View {
        VStack(spacing: 8) {
            if item.isEmpty {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                Text("Empty")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#9CA3AF"))
            } else {
                Text(item.icon)
                    .font(.system(size: 40))
                Text(item.name)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .padding(16)
        .background(Color(hex: "#243447"))
        .cornerRadius(12)
    }
}

#Preview {
    CharacterView()
        .environmentObject(UserProgressManager.shared)
}

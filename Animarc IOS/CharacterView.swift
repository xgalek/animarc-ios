//
//  CharacterView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

struct CharacterView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @State private var showProfile = false
    @State private var showChallengeAlert = false
    @State private var selectedPortalItem: PortalItem?
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
    
    // Real inventory data
    @State private var inventory: PortalInventory?
    @State private var isLoadingInventory = false
    @State private var inventoryError: String?
    
    // Inventory popup state
    @State private var showInventoryPopup = false
    @State private var selectedRankFilter: String = "ALL"
    @State private var showUnequipConfirm = false
    @State private var showSlotFullAlert = false
    @State private var selectedItemForAction: PortalItem?
    
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
                        
                        // Equipped Items Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("EQUIPPED ITEMS")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            if isLoadingInventory {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(.white)
                                    Spacer()
                                }
                                .padding(.vertical, 40)
                            } else if let error = inventoryError {
                                VStack(spacing: 12) {
                                    Text("Failed to load inventory")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                    Button("Retry") {
                                        Task {
                                            await loadInventory()
                                        }
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(hex: "#6B46C1"))
                                    .cornerRadius(8)
                                }
                                .padding(.vertical, 40)
                            } else {
                                let equippedItems = (inventory?.items ?? []).filter { $0.equipped }
                                let emptySlots = max(0, 8 - equippedItems.count)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8)
                                ], spacing: 8) {
                                    // Show equipped items
                                    ForEach(equippedItems) { item in
                                        EquippedSlot(item: item)
                                    }
                                    
                                    // Show empty slots
                                    ForEach(0..<emptySlots, id: \.self) { _ in
                                        EmptySlot {
                                            showInventoryPopup = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Manage Inventory Button
                        Button(action: {
                            showInventoryPopup = true
                        }) {
                            Text("MANAGE INVENTORY")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#F59E0B"))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        
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
            .alert("Unequip Item?", isPresented: $showUnequipConfirm) {
                Button("Cancel", role: .cancel) {
                    selectedItemForAction = nil
                }
                Button("Unequip", role: .destructive) {
                    if let item = selectedItemForAction {
                        Task {
                            await unequipItem(item)
                        }
                    }
                    selectedItemForAction = nil
                }
            }
            .alert("Inventory Full", isPresented: $showSlotFullAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You have 8/8 equipment slots filled. Unequip an item first.")
            }
            .task {
                await loadInventory()
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
            .sheet(isPresented: $showInventoryPopup) {
                InventoryPopupView(
                    inventory: $inventory,
                    selectedRankFilter: $selectedRankFilter,
                    onItemTap: { item in
                        handleInventoryItemTap(item)
                    },
                    onDismiss: {
                        showInventoryPopup = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Inventory Loading
    
    /// Load user's portal inventory from Supabase
    private func loadInventory() async {
        guard let userId = await getCurrentUserId() else {
            print("CharacterView: No authenticated user")
            inventoryError = "Not authenticated"
            return
        }
        
        isLoadingInventory = true
        inventoryError = nil
        
        do {
            inventory = try await SupabaseManager.shared.fetchOrCreateInventory(userId: userId)
            print("CharacterView: Loaded inventory with \(inventory?.items.count ?? 0) items")
        } catch {
            print("CharacterView: Failed to load inventory: \(error)")
            inventoryError = error.localizedDescription
            inventory = nil
        }
        
        isLoadingInventory = false
    }
    
    /// Get current authenticated user ID
    private func getCurrentUserId() async -> UUID? {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            return session.user.id
        } catch {
            print("CharacterView: Failed to get user ID: \(error)")
            return nil
        }
    }
    
    /// Handle tap on inventory item in popup
    private func handleInventoryItemTap(_ item: PortalItem) {
        if item.equipped {
            // Show unequip confirmation
            selectedItemForAction = item
            showUnequipConfirm = true
        } else {
            // Try to equip
            Task {
                await equipItem(item)
            }
        }
    }
    
    /// Equip an item
    private func equipItem(_ item: PortalItem) async {
        guard let userId = await getCurrentUserId() else {
            print("CharacterView: No authenticated user")
            return
        }
        
        do {
            // Check if already at 8 equipped items
            let equippedCount = try await SupabaseManager.shared.getEquippedItemCount(userId: userId)
            if equippedCount >= 8 {
                showSlotFullAlert = true
                return
            }
            
            // Equip the item
            let updatedInventory = try await SupabaseManager.shared.updateItemEquippedStatus(
                userId: userId,
                itemId: item.id,
                equipped: true
            )
            
            inventory = updatedInventory
        } catch {
            print("CharacterView: Failed to equip item: \(error)")
        }
    }
    
    /// Unequip an item
    private func unequipItem(_ item: PortalItem) async {
        guard let userId = await getCurrentUserId() else {
            print("CharacterView: No authenticated user")
            return
        }
        
        do {
            let updatedInventory = try await SupabaseManager.shared.updateItemEquippedStatus(
                userId: userId,
                itemId: item.id,
                equipped: false
            )
            
            inventory = updatedInventory
        } catch {
            print("CharacterView: Failed to unequip item: \(error)")
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
    let item: PortalItem
    
    var body: some View {
        VStack(spacing: 8) {
            // Item icon with rank badge
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: item.iconUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    case .failure:
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Rank badge
                Text(item.rolledRank)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(item.rankColor)
                    .cornerRadius(4)
                    .offset(x: 5, y: -5)
                
                // Equipped checkmark overlay
                if item.equipped {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#22C55E"))
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: -5, y: -5)
                }
            }
            
            // Item name
            Text(item.name)
                .font(.caption)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Show rank + stat value
            Text("\(item.rolledRank) | +\(item.statValue) \(item.statType)")
                .font(.caption2)
                .foregroundColor(item.rankColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .padding(16)
        .background(item.equipped ? Color(hex: "#243447").opacity(0.8) : Color(hex: "#243447"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(item.equipped ? Color(hex: "#22C55E") : item.rankColor.opacity(0.5), lineWidth: 2)
        )
        .cornerRadius(12)
    }
}

struct EquippedSlot: View {
    let item: PortalItem
    
    var body: some View {
        VStack(spacing: 6) {
            // Item icon with rank badge
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: item.iconUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 35, height: 35)
                    case .failure:
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 30))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Rank badge
                Text(item.rolledRank)
                    .font(.system(size: 8))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(item.rankColor)
                    .cornerRadius(3)
                    .offset(x: 3, y: -3)
            }
            
            // Item name
            Text(item.name)
                .font(.system(size: 10))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Stat bonus
            Text("+\(item.statValue) \(item.statType)")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(item.rankColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .padding(10)
        .background(Color(hex: "#243447"))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#22C55E"), lineWidth: 2)
        )
        .cornerRadius(10)
    }
}

struct EmptySlot: View {
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "plus")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#9CA3AF"))
            
            Text("Empty")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#9CA3AF"))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .padding(10)
        .background(Color(hex: "#374151"))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#9CA3AF").opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(10)
        .onTapGesture {
            onTap()
        }
    }
}

struct InventoryPopupView: View {
    @Binding var inventory: PortalInventory?
    @Binding var selectedRankFilter: String
    let onItemTap: (PortalItem) -> Void
    let onDismiss: () -> Void
    
    private let rankFilters = ["ALL", "E", "D", "C", "B", "A", "S"]
    
    private var filteredItems: [PortalItem] {
        guard let inventory = inventory else { return [] }
        let items = inventory.items
        
        if selectedRankFilter == "ALL" {
            return items
        } else {
            return items.filter { $0.rolledRank == selectedRankFilter }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with title and X button
                HStack {
                    Text("INVENTORY")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        onDismiss()
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
                .padding(.bottom, 16)
                
                Divider()
                    .background(Color(hex: "#9CA3AF").opacity(0.3))
                
                // Rank filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(rankFilters, id: \.self) { rank in
                            Button(action: {
                                selectedRankFilter = rank
                            }) {
                                Text(rank)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedRankFilter == rank ? .white : Color(hex: "#9CA3AF"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedRankFilter == rank
                                            ? (rank == "ALL" ? Color(hex: "#6B46C1") : getRankColor(rank))
                                            : Color(hex: "#374151")
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                
                Divider()
                    .background(Color(hex: "#9CA3AF").opacity(0.3))
                
                // Items grid
                ScrollView {
                    let items = filteredItems
                    if items.isEmpty {
                        VStack(spacing: 8) {
                            Text("No items")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                            Text(selectedRankFilter == "ALL" 
                                 ? "Complete portal sessions to earn items!"
                                 : "No \(selectedRankFilter)-rank items")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(items) { item in
                                InventorySlot(item: item)
                                    .onTapGesture {
                                        onItemTap(item)
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
    }
    
    private func getRankColor(_ rank: String) -> Color {
        switch rank {
        case "E": return Color(hex: "#9CA3AF")
        case "D": return Color(hex: "#3B82F6")
        case "C": return Color(hex: "#A855F7")
        case "B": return Color(hex: "#EF4444")
        case "A": return Color(hex: "#FBBF24")
        case "S": return Color(hex: "#FFD700")
        default: return Color(hex: "#9CA3AF")
        }
    }
}

#Preview {
    CharacterView()
        .environmentObject(UserProgressManager.shared)
}

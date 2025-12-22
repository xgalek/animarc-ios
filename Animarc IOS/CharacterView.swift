//
//  CharacterView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

struct CharacterView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @State private var showChallengeAlert = false
    @State private var showFindOpponent = false
    @State private var selectedPortalItem: PortalItem?
    @State private var showStatAllocation = false
    
    // Stat allocation system
    @State private var availablePoints: Int = 0
    @State private var tempStats: [String: Int] = [
        "Health": 150,
        "Attack": 10,
        "Defense": 10,
        "Speed": 10
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
    @State private var showSlotFullAlert = false
    
    // MARK: - Computed Properties
    
    /// Calculate stat bonuses from equipped items
    private var itemBonuses: [String: Int] {
        guard let inventory = inventory else { return [:] }
        let equippedItems = inventory.items.filter { $0.equipped }
        
        var bonuses: [String: Int] = ["Health": 0, "Attack": 0, "Defense": 0, "Speed": 0]
        
        for item in equippedItems {
            if let currentBonus = bonuses[item.statType] {
                bonuses[item.statType] = currentBonus + item.statValue
            }
        }
        
        return bonuses
    }
    
    /// Calculate Focus Power using formula: 1000 + (Health+Attack+Defense+Speed) + totalFocusMinutes + equipmentBonuses
    private var focusPower: Int {
        let equippedItems = (inventory?.items ?? []).filter { $0.equipped }
        guard let progress = progressManager.userProgress else { return 1000 }
        return UserProgress.calculateFocusPower(progress: progress, equippedItems: equippedItems)
    }
    
    // MARK: - View Components
    
    private var profileCardSection: some View {
        let equippedItems = (inventory?.items ?? []).filter { $0.equipped }
        // Create array of 8 slots (items or nil for empty)
        var slots: [PortalItem?] = Array(repeating: nil, count: 8)
        for (index, item) in equippedItems.enumerated() {
            if index < 8 {
                slots[index] = item
            }
        }
        let leftSlots = Array(slots[0..<4])
        let rightSlots = Array(slots[4..<8])
        
        return ZStack {
            // GIF background - fills entire card
            GIFImageView(gifName: "Character page gif small", contentMode: .scaleAspectFill)
                .clipped()
            
            // Content on top
            VStack(spacing: 8) {
                // Top: Level and Rank
                levelRankSection
                
                // Main layout: Left column + Right column with overlaid button
                ZStack(alignment: .bottom) {
                HStack(alignment: .top, spacing: 12) {
                    // Left: All 4 item slots
                    VStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { index in
                            profileItemSlot(item: leftSlots[index])
                                .onTapGesture {
                                    showInventoryPopup = true
                                }
                        }
                    }
                    
                    Spacer()
                    
                    // Right: All 4 item slots
                    VStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { index in
                                profileItemSlot(item: rightSlots[index])
                                    .onTapGesture {
                                        showInventoryPopup = true
                                    }
                            }
                        }
                    }
                    
                    // Inventory button overlaid at bottom center
                    Button(action: {
                        showInventoryPopup = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Inventory")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(hex: "#F59E0B"))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func profileItemSlot(item: PortalItem?) -> some View {
        Group {
            if let item = item {
                // Filled slot with item
                AsyncImage(url: URL(string: item.iconUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)
                            .frame(width: 70, height: 70)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .padding(6)
                    case .failure:
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 36))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .frame(width: 70, height: 70)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 70, height: 70)
                .background(Color(hex: "#243447"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(item.rankColor, lineWidth: 2)
                )
                .cornerRadius(8)
            } else {
                // Empty slot
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#243447"))
                    .frame(width: 70, height: 70)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#9CA3AF").opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    )
            }
        }
    }
    
    private var focusPowerGoldCardSection: some View {
        HStack(spacing: 12) {
            // Focus Power
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#F59E0B"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("FOCUS POWER")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                        .tracking(1)
                    
                    Text("\(focusPower)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Gold Display
            HStack(spacing: 8) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#FACC15"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("GOLD")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                        .tracking(1)
                    
                    Text("\(progressManager.userProgress?.gold ?? 0)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "#F59E0B"))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(hex: "#2D3748"))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
    
    private var statsCardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Allocate Points
            HStack {
                Text("STATS")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Allocate points (right-aligned)
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#FBBF24"))
                    
                    Text("+\(availablePoints) points")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#FBBF24"))
                }
                .modifier(PulsatingGlowModifier(isActive: availablePoints > 0))
                .onTapGesture {
                    originalStats = tempStats
                    workingStats = tempStats
                    showStatAllocation = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Stats Grid (2 columns: Left: Attack, Defense | Right: Health, Speed)
            HStack(alignment: .top, spacing: 20) {
                // Left Column
                VStack(alignment: .leading, spacing: 12) {
                    statRow(
                        label: "Attack",
                        baseValue: tempStats["Attack"] ?? 10,
                        bonus: itemBonuses["Attack"] ?? 0,
                        labelColor: Color(hex: "#80D8FF")
                    )
                    
                    statRow(
                        label: "Defense",
                        baseValue: tempStats["Defense"] ?? 10,
                        bonus: itemBonuses["Defense"] ?? 0,
                        labelColor: Color(hex: "#C080FF")
                    )
                }
                
                // Right Column
                VStack(alignment: .leading, spacing: 12) {
                    statRow(
                        label: "Health",
                        baseValue: tempStats["Health"] ?? 150,
                        bonus: itemBonuses["Health"] ?? 0,
                        labelColor: Color(hex: "#FF8080")
                    )
                    
                    statRow(
                        label: "Speed",
                        baseValue: tempStats["Speed"] ?? 10,
                        bonus: itemBonuses["Speed"] ?? 0,
                        labelColor: Color(hex: "#7CFF7C")
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(hex: "#2D3748"))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
    
    private func statRow(label: String, baseValue: Int, bonus: Int, labelColor: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(labelColor)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("\(baseValue)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                if bonus > 0 {
                    Text("+\(bonus)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#22C55E"))
                }
            }
        }
    }
    
    private var levelRankSection: some View {
        HStack(spacing: 8) {
            // XP Progress Bar - thicker with level on left and XP on right
            GeometryReader { geometry in
                let progressPercent = progressManager.levelProgress.progressPercent
                let progressWidth = geometry.size.width * (progressPercent / 100.0)
                
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "#9CA3AF").opacity(0.3))
                    
                    // Progress fill - orange
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "#FF9500"))
                        .frame(width: max(progressWidth, 0))
                    
                    // Level text on left and XP text on right
                    HStack {
                        // Level label on the left
                        if progressManager.isLoading {
                            Text("LV.1")
                                .font(.caption)
                                .foregroundColor(.white)
                                .pulsing()
                        } else {
                            Text("LV.\(progressManager.currentLevel)")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // XP text on the right
                        if progressManager.isLoading {
                            Text("0/0xp")
                                .font(.caption)
                                .foregroundColor(.white)
                                .pulsing()
                        } else {
                            let levelProgress = progressManager.levelProgress
                            Text("\(levelProgress.xpInCurrentLevel)/\(levelProgress.xpNeededForNext)xp")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .frame(height: 24)
            
            // Rank badge - minimalistic
            if progressManager.isLoading {
                Text("E-Rank")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#9CA3AF"))
                    .cornerRadius(8)
                    .pulsing()
            } else {
                Text("\(progressManager.currentRank)-Rank")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(progressManager.currentRankInfo.swiftUIColor)
                    .cornerRadius(8)
            }
        }
    }
    
    private func inventoryErrorView(_ error: String) -> some View {
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
    }
    
    private var challengeButton: some View {
        Button(action: {
            showFindOpponent = true
        }) {
            Text("⚔️ FIND OPPONENT")
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#FFE766"),
                            Color(hex: "#E87B41")
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: Color(hex: "#FFE766").opacity(0.4), radius: 15, x: 0, y: 0)
                .shadow(color: Color(hex: "#E87B41").opacity(0.3), radius: 25, x: 0, y: 0)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 40)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "#1A2332")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        profileCardSection
                        focusPowerGoldCardSection
                        statsCardSection
                        challengeButton
                    }
                }
            }
            .alert("Inventory Full", isPresented: $showSlotFullAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You have 8/8 equipment slots filled. Unequip an item first.")
            }
            .task {
                await loadInventory()
                await loadStats()
            }
            .onChange(of: progressManager.userProgress) { _ in
                Task {
                    await loadStats()
                }
            }
            .sheet(isPresented: $showStatAllocation) {
                StatAllocationSheet(
                    workingStats: $workingStats,
                    availablePoints: $availablePoints,
                    originalStats: originalStats,
                    isPresented: $showStatAllocation,
                    onSave: { savedStats in
                        Task {
                            await saveStats(savedStats)
                        }
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showInventoryPopup) {
                InventoryPopupView(
                    inventory: $inventory,
                    selectedRankFilter: $selectedRankFilter,
                    onEquip: { item in
                        await equipItem(item)
                    },
                    onUnequip: { item in
                        await unequipItem(item)
                    },
                    onDismiss: {
                        showInventoryPopup = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showFindOpponent) {
                FindOpponentView()
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
    
    // MARK: - Stats Loading and Saving
    
    /// Load stats from user progress
    private func loadStats() async {
        guard let progress = progressManager.userProgress else {
            // Use defaults if no progress loaded
            tempStats = [
                "Health": 150,
                "Attack": 10,
                "Defense": 10,
                "Speed": 10
            ]
            availablePoints = 0
            return
        }
        
        tempStats = [
            "Health": progress.statHealth,
            "Attack": progress.statAttack,
            "Defense": progress.statDefense,
            "Speed": progress.statSpeed
        ]
        availablePoints = progress.availableStatPoints
    }
    
    /// Save stat allocation to database
    private func saveStats(_ savedStats: [String: Int]) async {
        guard let userId = await getCurrentUserId() else {
            print("CharacterView: No authenticated user")
            return
        }
        
        guard let originalHealth = originalStats["Health"],
              let originalAttack = originalStats["Attack"],
              let originalDefense = originalStats["Defense"],
              let originalSpeed = originalStats["Speed"] else {
            print("CharacterView: Missing original stats")
            return
        }
        
        let newHealth = savedStats["Health"] ?? originalHealth
        let newAttack = savedStats["Attack"] ?? originalAttack
        let newDefense = savedStats["Defense"] ?? originalDefense
        let newSpeed = savedStats["Speed"] ?? originalSpeed
        
        // Calculate points spent
        // Health increases by 5 per point, other stats by 1 per point
        let healthPointsSpent = (newHealth - originalHealth) / 5
        let otherPointsSpent = (newAttack - originalAttack) + (newDefense - originalDefense) + (newSpeed - originalSpeed)
        let pointsSpent = healthPointsSpent + otherPointsSpent
        
        do {
            let updatedProgress = try await SupabaseManager.shared.updateStatAllocation(
                userId: userId,
                statHealth: newHealth,
                statAttack: newAttack,
                statDefense: newDefense,
                statSpeed: newSpeed,
                pointsSpent: pointsSpent
            )
            
            // Update local state
            tempStats = savedStats
            availablePoints = updatedProgress.availableStatPoints
            
            // Refresh progress manager
            progressManager.userProgress = updatedProgress
        } catch {
            print("CharacterView: Failed to save stats: \(error)")
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
                
                Divider()
                    .background(Color(hex: "#9CA3AF").opacity(0.3))
                
                // Stats with controls (Health, Attack, Defense, Speed)
                VStack(spacing: 16) {
                    StatRowWithControls(
                        icon: "❤️",
                        label: "Health",
                        value: Binding(
                            get: { workingStats["Health"] ?? (originalStats["Health"] ?? 150) },
                            set: { workingStats["Health"] = $0 }
                        ),
                        originalValue: originalStats["Health"] ?? 150,
                        availablePoints: $tempAvailablePoints,
                        step: 5
                    )
                    
                    StatRowWithControls(
                        icon: "⚔️",
                        label: "Attack",
                        value: Binding(
                            get: { workingStats["Attack"] ?? (originalStats["Attack"] ?? 10) },
                            set: { workingStats["Attack"] = $0 }
                        ),
                        originalValue: originalStats["Attack"] ?? 10,
                        availablePoints: $tempAvailablePoints,
                        step: 1
                    )
                    
                    StatRowWithControls(
                        icon: "🛡️",
                        label: "Defense",
                        value: Binding(
                            get: { workingStats["Defense"] ?? (originalStats["Defense"] ?? 10) },
                            set: { workingStats["Defense"] = $0 }
                        ),
                        originalValue: originalStats["Defense"] ?? 10,
                        availablePoints: $tempAvailablePoints,
                        step: 1
                    )
                    
                    StatRowWithControls(
                        icon: "⚡",
                        label: "Speed",
                        value: Binding(
                            get: { workingStats["Speed"] ?? (originalStats["Speed"] ?? 10) },
                            set: { workingStats["Speed"] = $0 }
                        ),
                        originalValue: originalStats["Speed"] ?? 10,
                        availablePoints: $tempAvailablePoints,
                        step: 1
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
    let step: Int
    
    init(icon: String, label: String, value: Binding<Int>, originalValue: Int, availablePoints: Binding<Int>, step: Int = 1) {
        self.icon = icon
        self.label = label
        self._value = value
        self.originalValue = originalValue
        self._availablePoints = availablePoints
        self.step = step
    }
    
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
                    value -= step
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
                    value += step
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
        ZStack(alignment: .topTrailing) {
            // Item icon - larger and centered
            AsyncImage(url: URL(string: item.iconUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(.white)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                case .failure:
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 60))
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
    let onEquip: (PortalItem) async -> Void
    let onUnequip: (PortalItem) async -> Void
    let onDismiss: () -> Void
    
    @State private var selectedItem: PortalItem?
    
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
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(items) { item in
                                InventorySlot(item: item)
                                    .onTapGesture {
                                        selectedItem = item
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailsPopup(
                item: item,
                onClose: {
                    selectedItem = nil
                },
                onEquip: {
                    Task {
                        await onEquip(item)
                        selectedItem = nil
                    }
                },
                onUnequip: {
                    Task {
                        await onUnequip(item)
                        selectedItem = nil
                    }
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
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

struct ItemDetailsPopup: View {
    let item: PortalItem
    let onClose: () -> Void
    let onEquip: () -> Void
    let onUnequip: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Large item image with rank badge
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
                                .frame(width: 150, height: 150)
                        case .failure:
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 100))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    // Rank badge
                    Text(item.rolledRank)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.rankColor)
                        .cornerRadius(6)
                        .offset(x: 10, y: -10)
                }
                .padding(.top, 50)
                
                // Item name
                Text(item.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Rank display
                Text("\(item.rolledRank)-Rank")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(item.rankColor)
                
                // Stats display
                Text("+\(item.statValue) \(item.statType)")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#374151"))
                    .cornerRadius(12)
                
                Spacer()
                
                // Bottom button row
                HStack(spacing: 16) {
                    // Close button (left)
                    Button(action: {
                        onClose()
                    }) {
                        Text("Close")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#374151"))
                            .cornerRadius(12)
                    }
                    
                    // Equip/Unequip button (right)
                    Button(action: {
                        if item.equipped {
                            onUnequip()
                        } else {
                            onEquip()
                        }
                    }) {
                        Text(item.equipped ? "Unequip" : "Equip")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(item.equipped ? Color(hex: "#EF4444") : Color(hex: "#6B46C1"))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Border Glow Pulse Modifier

struct BorderGlowPulseModifier: ViewModifier {
    let isActive: Bool
    @State private var glowOpacity: Double = 0.3
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        Color(hex: "#FBBF24"),
                        lineWidth: isActive ? 2 : 0
                    )
                    .shadow(
                        color: isActive ? Color(hex: "#FBBF24").opacity(glowOpacity) : .clear,
                        radius: isActive ? 8 : 0
                    )
                    .shadow(
                        color: isActive ? Color(hex: "#FBBF24").opacity(glowOpacity * 0.5) : .clear,
                        radius: isActive ? 12 : 0
                    )
            )
            .onAppear {
                if isActive {
                    startPulsing()
                }
            }
            .onChange(of: isActive) { newValue in
                if newValue {
                    startPulsing()
                } else {
                    glowOpacity = 0.3
                }
            }
    }
    
    private func startPulsing() {
        withAnimation(
            Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 0.8
        }
    }
}

// MARK: - Pulsating Glow Modifier

struct PulsatingGlowModifier: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: isActive ? Color(hex: "#FBBF24").opacity(isPulsing ? 0.8 : 0.3) : .clear,
                radius: isActive ? (isPulsing ? 10 : 4) : 0
            )
            .shadow(
                color: isActive ? Color(hex: "#FBBF24").opacity(isPulsing ? 0.4 : 0.1) : .clear,
                radius: isActive ? (isPulsing ? 16 : 8) : 0
            )
            .onAppear {
                if isActive {
                    startPulsing()
                }
            }
            .onChange(of: isActive) { newValue in
                if newValue {
                    startPulsing()
                } else {
                    isPulsing = false
                }
            }
    }
    
    private func startPulsing() {
        withAnimation(
            Animation.easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
        ) {
            isPulsing = true
        }
    }
}

#Preview {
    CharacterView()
        .environmentObject(UserProgressManager.shared)
}

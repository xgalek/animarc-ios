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
    @State private var showPortalRaid = false
    @State private var selectedPortalItem: PortalItem?
    @State private var showStatAllocation = false
    @State private var showLevelUpModal = false
    @State private var showPurchaseStats = false
    
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
                ZStack {
                    // Slot background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#243447"))
                        .frame(width: 70, height: 70)
                    
                    // Glow effect behind the actual item image based on rank
                    Circle()
                        .fill(item.rankColor.opacity(0.4))
                        .frame(width: 56, height: 56)
                        .blur(radius: 10)
                        .shadow(color: item.rankColor.opacity(0.7), radius: 12, x: 0, y: 0)
                        .shadow(color: item.rankColor.opacity(0.5), radius: 8, x: 0, y: 0)
                    
                    // Item image (smaller size)
                    AsyncImage(url: URL(string: item.iconUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .tint(.white)
                                .frame(width: 50, height: 50)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                        case .failure:
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 28))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .frame(width: 50, height: 50)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 50, height: 50)
                }
                .frame(width: 70, height: 70)
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
            
            // Gold Display (tappable to open purchase stats)
            Button(action: { showPurchaseStats = true }) {
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
            // XP Progress Bar - animated with micro-interactions
            AnimatedXPProgressBar(
                levelProgress: progressManager.levelProgress,
                isLoading: progressManager.isLoading,
                previousXP: progressManager.previousTotalXP,
                previousLevel: progressManager.previousLevel,
                shouldAnimate: progressManager.shouldAnimateXPChange
            )
            .frame(height: 24)
            
            // Rank badge
            if progressManager.isLoading {
                HStack(spacing: 2) {
                    Image("E_rank")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                    Text("E-Rank")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#4A90A4"))
                }
                .pulsing()
            } else {
                HStack(spacing: 2) {
                    if let badgeName = progressManager.currentRankInfo.badgeImageName {
                        Image(badgeName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                    }
                    Text("\(progressManager.currentRank)-Rank")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(progressManager.currentRankInfo.swiftUIColor)
                }
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
            showPortalRaid = true
        }) {
            Text("⚔️ RAID PORTAL")
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
                    }
                    .padding(.bottom, 120) // Extra padding for fixed button
                }
                
                // Fixed bottom button - positioned above tab bar
                VStack {
                    Spacer()
                    
                    Button(action: {
                        showPortalRaid = true
                    }) {
                        Text("⚔️ RAID PORTAL")
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
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 10) // Small spacing above tab bar
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
            .sheet(isPresented: $showPurchaseStats) {
                PurchaseStatsSheet(
                    isPresented: $showPurchaseStats,
                    itemBonuses: itemBonuses,
                    onPurchase: { updatedProgress in
                        progressManager.userProgress = updatedProgress
                        tempStats = [
                            "Health": updatedProgress.statHealth,
                            "Attack": updatedProgress.statAttack,
                            "Defense": updatedProgress.statDefense,
                            "Speed": updatedProgress.statSpeed
                        ]
                        availablePoints = updatedProgress.availableStatPoints
                    }
                )
                .environmentObject(progressManager)
                .presentationDetents([.fraction(0.6)])
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
                    onSell: { item in
                        await sellItem(item)
                    },
                    onDismiss: {
                        showInventoryPopup = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: showInventoryPopup) { _, isShowing in
                // Reload inventory when opening inventory popup to show latest items
                if isShowing {
                    Task {
                        await loadInventory()
                    }
                }
            }
            .sheet(isPresented: $showPortalRaid) {
                PortalRaidView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showLevelUpModal) {
                LevelUpModalView(
                    oldLevel: progressManager.pendingLevelUp?.oldLevel ?? 1,
                    newLevel: progressManager.pendingLevelUp?.newLevel ?? 1,
                    rankUp: progressManager.pendingRankUp
                ) {
                    // On dismiss, clear level up
                    progressManager.pendingLevelUp = nil
                    progressManager.pendingRankUp = nil
                    showLevelUpModal = false
                }
            }
            .onChange(of: showPortalRaid) { _, isShowing in
                // When PortalRaidView dismisses (user clicked "Return Home"), check for pending level ups and refresh inventory
                if !isShowing {
                    // Reload inventory to show any new items from defeated bosses
                    Task {
                        await loadInventory()
                    }
                    
                    // Small delay to ensure PortalRaidResultView has fully dismissed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Only show if no other modals are showing
                        if !showStatAllocation && !showInventoryPopup && progressManager.pendingLevelUp != nil {
                            showLevelUpModal = true
                        }
                    }
                }
            }
            .onAppear {
                // Check for pending level ups when view appears (e.g., navigating from HomeView)
                if !showStatAllocation && !showInventoryPopup && !showPortalRaid && progressManager.pendingLevelUp != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if !showStatAllocation && !showInventoryPopup && !showPortalRaid {
                            showLevelUpModal = true
                        }
                    }
                }
            }
            .onChange(of: progressManager.userProgress?.currentLevel) { _, newLevel in
                // Check for pending level up when level changes (detects level-ups while on CharacterView)
                if newLevel != nil && !showPortalRaid && !showStatAllocation && !showInventoryPopup {
                    if progressManager.pendingLevelUp != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if !showPortalRaid && !showStatAllocation && !showInventoryPopup {
                                showLevelUpModal = true
                            }
                        }
                    }
                }
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
    
    /// Sell an item for gold
    private func sellItem(_ item: PortalItem) async {
        guard let userId = await getCurrentUserId() else {
            print("CharacterView: No authenticated user")
            return
        }
        
        do {
            let result = try await SupabaseManager.shared.sellItem(userId: userId, itemId: item.id)
            inventory = result.inventory
            
            // Refresh user progress to reflect updated gold
            await progressManager.refreshProgress()
            
            let impactFeedback = UINotificationFeedbackGenerator()
            impactFeedback.notificationOccurred(.success)
        } catch {
            print("CharacterView: Failed to sell item: \(error)")
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
                
                // Available Points Display with animation
                HStack(spacing: 4) {
                    Text("Available Points:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    AnimatedNumberText(value: tempAvailablePoints, baseColor: Color(hex: "#FBBF24"))
                        .font(.system(size: 16, weight: .bold))
                }
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

// MARK: - Purchase Stats Sheet (Gold -> Stat Points)

struct PurchaseStatsSheet: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @Binding var isPresented: Bool
    let itemBonuses: [String: Int]
    let onPurchase: (UserProgress) -> Void
    
    @State private var isPurchasing: [String: Bool] = [:]
    
    private let goldCost = 200
    
    private var currentGold: Int {
        progressManager.userProgress?.gold ?? 0
    }
    
    private var canAfford: Bool {
        currentGold >= goldCost
    }
    
    private struct StatInfo {
        let key: String
        let label: String
        let icon: String
        let color: Color
        let bgColor: Color
    }
    
    private let stats: [StatInfo] = [
        StatInfo(key: "Attack", label: "Attack", icon: "bolt.fill",
                 color: Color(hex: "#80D8FF"), bgColor: Color(hex: "#80D8FF")),
        StatInfo(key: "Defense", label: "Defense", icon: "shield.fill",
                 color: Color(hex: "#C080FF"), bgColor: Color(hex: "#C080FF")),
        StatInfo(key: "Health", label: "Health", icon: "heart.fill",
                 color: Color(hex: "#FF8080"), bgColor: Color(hex: "#FF8080")),
        StatInfo(key: "Speed", label: "Speed", icon: "hare.fill",
                 color: Color(hex: "#7CFF7C"), bgColor: Color(hex: "#7CFF7C"))
    ]
    
    private func statValue(for key: String) -> Int {
        guard let progress = progressManager.userProgress else { return 0 }
        switch key {
        case "Health": return progress.statHealth
        case "Attack": return progress.statAttack
        case "Defense": return progress.statDefense
        case "Speed": return progress.statSpeed
        default: return 0
        }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Purchase Stats")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Text("UPGRADE YOUR ABILITIES")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .tracking(1.5)
                    }
                    
                    Spacer()
                    
                    // Gold badge
                    HStack(spacing: 6) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "#F59E0B"))
                        
                        Text("\(currentGold)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // Stat rows
                VStack(spacing: 10) {
                    ForEach(stats, id: \.key) { stat in
                        statPurchaseRow(stat: stat)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Close button
                Button(action: { isPresented = false }) {
                    Text("Close")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
    
    private func statPurchaseRow(stat: StatInfo) -> some View {
        let bonus = itemBonuses[stat.key] ?? 0
        let base = statValue(for: stat.key)
        let purchasing = isPurchasing[stat.key] ?? false
        
        return HStack(spacing: 0) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(stat.bgColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(stat.bgColor.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: stat.icon)
                    .font(.system(size: 20))
                    .foregroundColor(stat.color)
            }
            .padding(.trailing, 12)
            
            // Stat label + value
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#E2E8F0"))
                
                HStack(spacing: 4) {
                    Text("\(base)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(stat.color)
                    
                    if bonus > 0 {
                        Text("+\(bonus)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#22C55E"))
                    }
                }
            }
            
            Spacer()
            
            // Buy button
            Button(action: {
                Task { await purchaseStat(stat.key) }
            }) {
                HStack(spacing: 6) {
                    Text("\(goldCost)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                    
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.7))
                    
                    Rectangle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 1, height: 18)
                    
                    Text("BUY")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    canAfford && !purchasing
                        ? Color(hex: "#F59E0B")
                        : Color(hex: "#F59E0B").opacity(0.3)
                )
                .cornerRadius(12)
                .shadow(
                    color: canAfford && !purchasing ? Color(hex: "#F59E0B").opacity(0.3) : .clear,
                    radius: 8, x: 0, y: 2
                )
            }
            .disabled(!canAfford || purchasing)
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color(hex: "#334155").opacity(0.4), Color(hex: "#0F172A").opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func purchaseStat(_ statType: String) async {
        isPurchasing[statType] = true
        defer { isPurchasing[statType] = false }
        
        guard let userId = await getCurrentUserId() else { return }
        
        do {
            let updated = try await SupabaseManager.shared.purchaseStatWithGold(
                userId: userId, statType: statType
            )
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            progressManager.userProgress = updated
            onPurchase(updated)
        } catch {
            print("PurchaseStatsSheet: Failed to purchase stat: \(error)")
        }
    }
    
    private func getCurrentUserId() async -> UUID? {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            return session.user.id
        } catch {
            return nil
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
    
    @State private var previousValue: Int
    
    init(icon: String, label: String, value: Binding<Int>, originalValue: Int, availablePoints: Binding<Int>, step: Int = 1) {
        self.icon = icon
        self.label = label
        self._value = value
        self.originalValue = originalValue
        self._availablePoints = availablePoints
        self.step = step
        _previousValue = State(initialValue: value.wrappedValue)
    }
    
    var canDecrement: Bool {
        value > originalValue
    }
    
    var canIncrement: Bool {
        availablePoints > 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 16))
                Text("\(label):")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                // Animated number display
                AnimatedNumberText(value: value)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Spacer()
            
            // Decrement button
            Button(action: {
                if canDecrement {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    previousValue = value
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
            .buttonStyle(StatButtonStyle())
            
            // Increment button
            Button(action: {
                if canIncrement {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    previousValue = value
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
            .buttonStyle(StatButtonStyle())
        }
    }
}

// MARK: - Stat Button Style (with press animation)
struct StatButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct InventorySlot: View {
    let item: PortalItem
    
    var body: some View {
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
    let onSell: (PortalItem) async -> Void
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
                // Top bar with title, count, and X button
                HStack {
                    HStack(spacing: 8) {
                        Text("INVENTORY")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(inventory?.items.count ?? 0)/\(PortalInventory.maxItems)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                    
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
                },
                onSell: {
                    Task {
                        await onSell(item)
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
        case "E": return Color(hex: "#4A90A4")
        case "D": return Color(hex: "#3B82F6")
        case "C": return Color(hex: "#A855F7")
        case "B": return Color(hex: "#EF4444")
        case "A": return Color(hex: "#FBBF24")
        case "S": return Color(hex: "#FFD700")
        default: return Color(hex: "#4A90A4")
        }
    }
}

struct ItemDetailsPopup: View {
    let item: PortalItem
    let onClose: () -> Void
    let onEquip: () -> Void
    let onUnequip: () -> Void
    let onSell: () -> Void
    
    @State private var showSellConfirmation = false
    
    var body: some View {
        ZStack {
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
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
                .padding(.top, 50)
                
                Text(item.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text("\(item.rolledRank)-Rank")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(item.rankColor)
                
                Text("+\(item.statValue) \(item.statType)")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#374151"))
                    .cornerRadius(12)
                
                Spacer()
                
                // Bottom button row
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        // Close button
                        Button(action: { onClose() }) {
                            Text("Close")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "#374151"))
                                .cornerRadius(12)
                        }
                        
                        // Equip/Unequip button
                        Button(action: {
                            if item.equipped { onUnequip() } else { onEquip() }
                        }) {
                            Text(item.equipped ? "Unequip" : "Equip")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(item.equipped ? Color(hex: "#EF4444") : Color(hex: "#6B46C1"))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Sell button
                    Button(action: { showSellConfirmation = true }) {
                        HStack(spacing: 6) {
                            Text("Sell")
                                .font(.system(size: 15, weight: .semibold))
                            
                            Text("\(item.sellPrice)")
                                .font(.system(size: 15, weight: .bold))
                            
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#F59E0B"))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .alert("Sell Item?", isPresented: $showSellConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sell for \(item.sellPrice) Gold", role: .destructive) {
                onSell()
            }
        } message: {
            Text("Sell \(item.name) (\(item.rolledRank)-Rank) for \(item.sellPrice) gold?")
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

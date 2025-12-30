//
//  SupabaseManager+Inventory.swift
//  Animarc IOS
//
//  Database methods for portal inventory system
//

import Foundation
import Supabase

// MARK: - Portal Inventory

extension SupabaseManager {
    
    /// Fetch user's portal inventory
    /// - Parameter userId: The user's UUID
    /// - Returns: PortalInventory if found, nil otherwise
    func fetchUserInventory(userId: UUID) async throws -> PortalInventory? {
        // Use array query instead of .single() to handle empty results gracefully
        let response: [PortalInventory] = try await client
            .from("portal_inventory")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        
        return response.first
    }
    
    /// Create empty inventory for new user
    /// - Parameter userId: The user's UUID
    /// - Returns: Newly created PortalInventory
    func createEmptyInventory(userId: UUID) async throws -> PortalInventory {
        struct NewInventory: Codable {
            let user_id: String
            let session_id: String?
            let items: [PortalItem]
        }
        
        let newInventory = NewInventory(
            user_id: userId.uuidString,
            session_id: nil,
            items: []
        )
        
        let response: [PortalInventory] = try await client
            .from("portal_inventory")
            .insert(newInventory)
            .select()
            .execute()
            .value
        
        guard let created = response.first else {
            throw GamificationError.userProgressNotFound // Reuse existing error type
        }
        
        return created
    }
    
    /// Fetch or create inventory record for user
    /// - Parameter userId: The user's UUID
    /// - Returns: Existing or new PortalInventory
    func fetchOrCreateInventory(userId: UUID) async throws -> PortalInventory {
        if let existing = try await fetchUserInventory(userId: userId) {
            return existing
        }
        return try await createEmptyInventory(userId: userId)
    }
}

// MARK: - Portal Item Configs

extension SupabaseManager {
    
    /// Fetch all portal item configurations (reference data)
    /// - Returns: Array of PortalItemConfig
    func fetchPortalItemConfigs() async throws -> [PortalItemConfig] {
        return try await client
            .from("portal_items_config")
            .select()
            .execute()
            .value
    }
}

// MARK: - Item Drops

extension SupabaseManager {
    
    /// Check if user is eligible for item drop (not dropped today)
    /// - Parameter userId: The user's UUID
    /// - Returns: True if eligible, false if already dropped today
    func canDropItem(userId: UUID) async throws -> Bool {
        let inventory = try await fetchOrCreateInventory(userId: userId)
        
        guard let lastDropDate = inventory.lastDropDate else {
            return true // Never dropped before
        }
        
        return !Calendar.current.isDateInToday(lastDropDate)
    }
    
    /// Drop random item for user based on their rank with rarity system
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - userRank: The user's current rank ("E", "D", "C", "B", "A", "S")
    ///   - isPro: Whether user has Pro subscription (affects drop rates)
    /// - Returns: PortalItem if dropped successfully, nil if not eligible or error
    func dropRandomItem(userId: UUID, userRank: String, isPro: Bool = false) async throws -> PortalItem? {
        // Check eligibility first
        guard try await canDropItem(userId: userId) else {
            return nil // Already dropped today
        }
        
        // Fetch all item configs
        let configs = try await fetchPortalItemConfigs()
        guard !configs.isEmpty else { return nil }
        
        // Randomly select one item
        guard let selectedConfig = configs.randomElement() else { return nil }
        
        // Determine rarity tier based on subscription status
        // Free: 70% same rank, 25% +1 rank, 5% +2 ranks
        // Pro: 50% same rank, 35% +1 rank, 15% +2 ranks (better rates)
        let rarityRoll = Int.random(in: 1...100)
        let effectiveRank: String
        if isPro {
            // Pro users get better drop rates
            if rarityRoll <= 50 {
                effectiveRank = userRank // 50% same rank
            } else if rarityRoll <= 85 {
                effectiveRank = getNextRank(userRank) // 35% +1 rank
            } else {
                effectiveRank = getNextRank(getNextRank(userRank)) // 15% +2 ranks
            }
        } else {
            // Free users: standard rates
            if rarityRoll <= 70 {
                effectiveRank = userRank // 70% same rank
            } else if rarityRoll <= 95 {
                effectiveRank = getNextRank(userRank) // 25% +1 rank
            } else {
                effectiveRank = getNextRank(getNextRank(userRank)) // 5% +2 ranks
            }
        }
        
        // Roll stat value based on effective rank
        let statValue = rollStatValue(config: selectedConfig, rank: effectiveRank)
        
        // Check if there are available equipment slots (max 8)
        let equippedCount = try await getEquippedItemCount(userId: userId)
        let shouldAutoEquip = equippedCount < 8
        
        // Create new item (store rolled rank for quality display)
        // Auto-equip if there are available slots
        let newItem = PortalItem(
            id: UUID(),
            name: selectedConfig.name,
            iconUrl: selectedConfig.iconUrl,
            statType: selectedConfig.statType,
            statValue: statValue,
            rolledRank: effectiveRank,  // Store the rank tier it rolled at
            equipped: shouldAutoEquip  // Auto-equip if slots available
        )
        
        // Add to inventory and update last drop date
        try await addItemToInventory(userId: userId, item: newItem)
        
        return newItem
    }
    
    // MARK: - Private Helpers
    
    /// Roll stat value based on rank ranges from config
    func rollStatValue(config: PortalItemConfig, rank: String) -> Int {
        let (min, max): (Int, Int) = {
            switch rank {
            case "E": return (config.rankEMin, config.rankEMax)
            case "D": return (config.rankDMin, config.rankDMax)
            case "C": return (config.rankCMin, config.rankCMax)
            case "B": return (config.rankBMin, config.rankBMax)
            case "A": return (config.rankAMin, config.rankAMax)
            case "S": return (config.rankSMin, config.rankSMax)
            default: return (config.rankEMin, config.rankEMax)
            }
        }()
        return Int.random(in: min...max)
    }
    
    /// Get next rank in progression
    func getNextRank(_ rank: String) -> String {
        switch rank {
        case "E": return "D"
        case "D": return "C"
        case "C": return "B"
        case "B": return "A"
        case "A": return "S"
        case "S": return "S" // Cap at S
        default: return rank
        }
    }
    
    /// Add item to user's inventory and update last drop date
    private func addItemToInventory(userId: UUID, item: PortalItem) async throws {
        var inventory = try await fetchOrCreateInventory(userId: userId)
        inventory.items.append(item)
        inventory.lastDropDate = Date()
        
        struct InventoryUpdate: Codable {
            let items: [PortalItem]
            let last_drop_date: Date
        }
        
        let update = InventoryUpdate(items: inventory.items, last_drop_date: Date())
        
        try await client
            .from("portal_inventory")
            .update(update)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
}

// MARK: - Item Equip/Unequip

extension SupabaseManager {
    
    /// Update equipped status of an item in user's inventory
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - itemId: The item's UUID to update
    ///   - equipped: New equipped status
    /// - Returns: Updated PortalInventory
    func updateItemEquippedStatus(userId: UUID, itemId: UUID, equipped: Bool) async throws -> PortalInventory {
        var inventory = try await fetchOrCreateInventory(userId: userId)
        
        // Find and update the item
        if let index = inventory.items.firstIndex(where: { $0.id == itemId }) {
            var updatedItem = inventory.items[index]
            updatedItem.equipped = equipped
            inventory.items[index] = updatedItem
        } else {
            throw GamificationError.userProgressNotFound // Reuse error type
        }
        
        struct InventoryUpdate: Codable {
            let items: [PortalItem]
        }
        
        let update = InventoryUpdate(items: inventory.items)
        
        let response: [PortalInventory] = try await client
            .from("portal_inventory")
            .update(update)
            .eq("user_id", value: userId.uuidString)
            .select()
            .execute()
            .value
        
        guard let updated = response.first else {
            throw GamificationError.userProgressNotFound
        }
        
        return updated
    }
    
    /// Get count of currently equipped items
    /// - Parameter userId: The user's UUID
    /// - Returns: Number of equipped items
    func getEquippedItemCount(userId: UUID) async throws -> Int {
        let inventory = try await fetchOrCreateInventory(userId: userId)
        return inventory.items.filter { $0.equipped }.count
    }
}

// MARK: - Portal Boss Item Drops

extension SupabaseManager {
    
    /// Drop random item for user after defeating a portal boss
    /// This is separate from daily drops - no eligibility check needed
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - bossRank: The boss's rank ("E", "D", "C", "B", "A", "S")
    /// - Returns: PortalItem if dropped successfully, nil if error
    func dropPortalBossItem(userId: UUID, bossRank: String, isPro: Bool = false) async throws -> PortalItem? {
        // Fetch all item configs
        let configs = try await fetchPortalItemConfigs()
        guard !configs.isEmpty else { return nil }
        
        // Randomly select one item
        guard let selectedConfig = configs.randomElement() else { return nil }
        
        // Determine rarity tier based on subscription status
        // Free: 70% same rank, 25% +1 rank, 5% +2 ranks
        // Pro: 50% same rank, 35% +1 rank, 15% +2 ranks (better rates)
        let rarityRoll = Int.random(in: 1...100)
        let effectiveRank: String
        if isPro {
            // Pro users get better drop rates
            if rarityRoll <= 50 {
                effectiveRank = bossRank // 50% same rank as boss
            } else if rarityRoll <= 85 {
                effectiveRank = getNextRank(bossRank) // 35% +1 rank from boss
            } else {
                effectiveRank = getNextRank(getNextRank(bossRank)) // 15% +2 ranks from boss
            }
        } else {
            // Free users: standard rates
            if rarityRoll <= 70 {
                effectiveRank = bossRank // 70% same rank as boss (minimum)
            } else if rarityRoll <= 95 {
                effectiveRank = getNextRank(bossRank) // 25% +1 rank from boss
            } else {
                effectiveRank = getNextRank(getNextRank(bossRank)) // 5% +2 ranks from boss
            }
        }
        
        // Roll stat value based on effective rank
        let statValue = rollStatValue(config: selectedConfig, rank: effectiveRank)
        
        // Check if there are available equipment slots (max 8)
        let equippedCount = try await getEquippedItemCount(userId: userId)
        let shouldAutoEquip = equippedCount < 8
        
        // Create new item (store rolled rank for quality display)
        // Auto-equip if there are available slots
        let newItem = PortalItem(
            id: UUID(),
            name: selectedConfig.name,
            iconUrl: selectedConfig.iconUrl,
            statType: selectedConfig.statType,
            statValue: statValue,
            rolledRank: effectiveRank,  // Store the rank tier it rolled at
            equipped: shouldAutoEquip  // Auto-equip if slots available
        )
        
        // Add to inventory (don't update lastDropDate - that's for daily drops only)
        var inventory = try await fetchOrCreateInventory(userId: userId)
        inventory.items.append(newItem)
        
        struct InventoryUpdate: Codable {
            let items: [PortalItem]
        }
        
        let update = InventoryUpdate(items: inventory.items)
        
        try await client
            .from("portal_inventory")
            .update(update)
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        return newItem
    }
}


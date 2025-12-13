//
//  QuoteManager.swift
//  Animarc IOS
//
//  Manages daily motivational quotes with typing effect tracking
//

import Foundation

/// Manager for daily motivational quotes
@MainActor
final class QuoteManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = QuoteManager()
    
    // MARK: - UserDefaults Keys
    
    private let currentDailyQuoteKey = "currentDailyQuote"
    private let quoteSelectedDateKey = "quoteSelectedDate"
    private let lastTypingEffectDateKey = "lastTypingEffectDate"
    
    // MARK: - Quote List
    
    private let quotes: [String] = [
        "Focus is the art of saying no.",
        "One task at a time, one step at a time.",
        "Even the longest journey begins with a single focus session.",
        "Your future self is watching. Make them proud.",
        "The quiet mind is the powerful mind.",
        "Progress, not perfection.",
        "Small steps lead to big dreams.",
        "Every focus session is training for your goals.",
        "The master has failed more times than the beginner has tried.",
        "Discipline is choosing what you want most over what you want now.",
        "A calm sea never made a skilled sailor.",
        "Your only competition is who you were yesterday.",
        "The pain of discipline weighs ounces. The pain of regret weighs tons.",
        "Focus on the step in front of you, not the whole staircase.",
        "Greatness is built one focused hour at a time.",
        "The quieter you become, the more you can hear.",
        "Every champion was once a beginner who refused to give up."
    ]
    
    // MARK: - Private Init
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Gets the current daily quote, selecting a new one if it's a new day
    func getCurrentQuote() -> String {
        let todayString = getTodayDateString()
        
        // Check if we have a quote for today
        if let storedDate = UserDefaults.standard.string(forKey: quoteSelectedDateKey),
           let storedQuote = UserDefaults.standard.string(forKey: currentDailyQuoteKey),
           storedDate == todayString {
            return storedQuote
        }
        
        // It's a new day or no quote exists - select a new one
        let newQuote = selectNewQuote()
        UserDefaults.standard.set(newQuote, forKey: currentDailyQuoteKey)
        UserDefaults.standard.set(todayString, forKey: quoteSelectedDateKey)
        
        return newQuote
    }
    
    /// Returns true if typing effect should be shown (hasn't been shown today)
    func shouldShowTypingEffect() -> Bool {
        let todayString = getTodayDateString()
        
        if let lastShownDate = UserDefaults.standard.string(forKey: lastTypingEffectDateKey),
           lastShownDate == todayString {
            return false // Already shown today
        }
        
        return true
    }
    
    /// Marks typing effect as shown for today
    func markTypingEffectShown() {
        let todayString = getTodayDateString()
        UserDefaults.standard.set(todayString, forKey: lastTypingEffectDateKey)
    }
    
    // MARK: - Private Methods
    
    /// Randomly selects a new quote from the list
    private func selectNewQuote() -> String {
        return quotes.randomElement() ?? quotes[0]
    }
    
    /// Gets today's date string in yyyy-MM-dd format
    private func getTodayDateString() -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        
        return dateFormatter.string(from: today)
    }
}






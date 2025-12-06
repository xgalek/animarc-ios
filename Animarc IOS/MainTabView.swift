//
//  MainTabView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

// UIColor extension for hex color support
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

struct MainTabView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    
    init() {
        // Style the tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "#1A2332")
        
        // Selected item color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(hex: "#8B5CF6")
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(hex: "#8B5CF6")
        ]
        
        // Unselected item color (muted gray)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hex: "#9CA3AF")
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(hex: "#9CA3AF")
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        TabView {
            // Home Tab
            HomeView()
                .environmentObject(progressManager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // Stats Tab
            StatsView()
                .environmentObject(progressManager)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            
            // Character Tab
            CharacterView()
                .environmentObject(progressManager)
                .tabItem {
                    Label("Character", systemImage: "sparkles")
                }
        }
        .tint(Color(hex: "#8B5CF6"))
    }
}

#Preview {
    MainTabView()
        .environmentObject(UserProgressManager.shared)
}

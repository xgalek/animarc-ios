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
    
    // Portal transition state - shared with HomeView
    @State private var showPortalTransition = false
    @State private var portalTransitionComplete: (() -> Void)? = nil
    
    init() {
        // Style the tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "#1A2332")
        
        // Selected item color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        
        // Unselected item color (darker gray for better contrast)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hex: "#6B7280")
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(hex: "#6B7280")
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        ZStack {
            TabView {
                // Home Tab
                HomeView(
                    showPortalTransition: $showPortalTransition,
                    onPortalTransitionComplete: { completion in
                        portalTransitionComplete = completion
                    }
                )
                    .environmentObject(progressManager)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                // Character Tab
                CharacterView()
                    .environmentObject(progressManager)
                    .tabItem {
                        Label("Character", systemImage: "shield.fill")
                    }
                
                // Stats Tab
                StatsView()
                    .environmentObject(progressManager)
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
                
                // Settings Tab
                ProfileView()
                    .environmentObject(progressManager)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(.white)
            
            // Portal transition overlay - covers everything including tab bar
            if showPortalTransition {
                PortalTransitionOverlay {
                    showPortalTransition = false
                    portalTransitionComplete?()
                    portalTransitionComplete = nil
                }
                .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(UserProgressManager.shared)
}

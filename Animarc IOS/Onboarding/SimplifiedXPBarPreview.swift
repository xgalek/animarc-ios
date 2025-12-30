//
//  SimplifiedXPBarPreview.swift
//  Animarc IOS
//
//  Simplified XP bar preview component for onboarding (visual only, no real data)
//

import SwiftUI

struct SimplifiedXPBarPreview: View {
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            let progressWidth = geometry.size.width * (animatedProgress / 100.0)
            
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#9CA3AF").opacity(0.3))
                
                // Animated progress fill - orange
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#FF9500"))
                    .frame(width: progressWidth)
                    .shadow(color: Color(hex: "#FF9500").opacity(0.5), radius: 4, x: 0, y: 0)
            }
        }
        .frame(height: 24)
        .onAppear {
            // Animate from 0 to 60% over 0.5 seconds
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = 60
            }
        }
    }
}

#Preview {
    SimplifiedXPBarPreview()
        .padding()
        .background(Color(hex: "#1A2332"))
}




//
//  Extensions.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI
import UIKit

// Color extension for hex color support
extension Color {
    init(hex: String) {
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
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// UIImage extension for GIF loading
extension UIImage {
    static func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: Double = 0
        
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)
                
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                    duration += delayTime
                } else {
                    duration += 0.1 // Default delay if not specified
                }
            }
        }
        
        return UIImage.animatedImage(with: images, duration: duration)
    }
}

// UIViewRepresentable wrapper for GIF animation
struct GIFImageView: UIViewRepresentable {
    let gifName: String
    var contentMode: UIView.ContentMode = .scaleAspectFit
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        
        // Load GIF from bundle
        if let path = Bundle.main.path(forResource: gifName, ofType: "gif"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let image = UIImage.gifImageWithData(data) {
            imageView.image = image
            imageView.startAnimating()
        }
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

// Avatar Button Component
struct AvatarButton: View {
    @Binding var showProfile: Bool
    
    var body: some View {
        Button(action: {
            showProfile = true
        }) {
            Image(systemName: "person.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color(hex: "#374151").opacity(0.8))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

// Shimmer Effect Modifier for Skeleton Loaders
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

// Pulsing Effect Modifier for Loading States
struct Pulsing: ViewModifier {
    @State private var opacity: Double = 0.3
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    opacity = 0.6
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(Shimmer())
    }
    
    func pulsing() -> some View {
        modifier(Pulsing())
    }
}

// MARK: - Animated Number Text Component
struct AnimatedNumberText: View {
    let value: Int
    let baseColor: Color
    @State private var displayedValue: Int
    @State private var previousValue: Int
    @State private var scale: CGFloat = 1.0
    @State private var colorFlash: Color? = nil
    
    init(value: Int, baseColor: Color = .white) {
        self.value = value
        self.baseColor = baseColor
        _displayedValue = State(initialValue: value)
        _previousValue = State(initialValue: value)
    }
    
    var body: some View {
        Text("\(displayedValue)")
            .foregroundColor(colorFlash ?? baseColor)
            .scaleEffect(scale)
            .animation(.easeOut(duration: 0.2), value: scale)
            .animation(.easeOut(duration: 0.3), value: colorFlash)
            .onChange(of: value) { oldValue, newValue in
                guard oldValue != newValue else { return }
                
                let isIncrease = newValue > oldValue
                
                // Trigger scale animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.2
                }
                
                // Flash color (green for increase, red for decrease)
                colorFlash = isIncrease ? Color(hex: "#22C55E") : Color(hex: "#EF4444")
                
                // Animate number counting
                let difference = abs(newValue - oldValue)
                let duration = min(0.5, Double(difference) * 0.05) // Faster for larger changes
                
                withAnimation(.linear(duration: duration)) {
                    displayedValue = newValue
                }
                
                // Reset scale and color after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 1.0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        colorFlash = nil
                    }
                }
            }
    }
}

// MARK: - Animated XP Progress Bar Component
struct AnimatedXPProgressBar: View {
    let levelProgress: LevelProgress
    let isLoading: Bool
    let previousXP: Int64?
    let previousLevel: Int?
    let shouldAnimate: Bool
    @State private var animatedProgress: Double = 0
    @State private var animatedXPInLevel: Int = 0
    @State private var animatedXPNeeded: Int = 0
    @State private var animatedLevel: Int = 1
    @State private var previousLevelState: Int = 1
    @State private var glowOpacity: Double = 0
    @State private var levelScale: CGFloat = 1.0
    @State private var hasAnimated: Bool = false
    
    init(levelProgress: LevelProgress, isLoading: Bool, previousXP: Int64? = nil, previousLevel: Int? = nil, shouldAnimate: Bool = false) {
        self.levelProgress = levelProgress
        self.isLoading = isLoading
        self.previousXP = previousXP
        self.previousLevel = previousLevel
        self.shouldAnimate = shouldAnimate
        
        // Initialize with previous values if animating, otherwise use current values
        if shouldAnimate, let prevXP = previousXP, let prevLevel = previousLevel {
            let prevProgress = LevelService.getLevelProgress(totalXP: Int(prevXP))
            _animatedProgress = State(initialValue: prevProgress.progressPercent)
            _animatedXPInLevel = State(initialValue: prevProgress.xpInCurrentLevel)
            _animatedXPNeeded = State(initialValue: prevProgress.xpNeededForNext)
            _animatedLevel = State(initialValue: prevLevel)
            _previousLevelState = State(initialValue: prevLevel)
        } else {
            _animatedProgress = State(initialValue: levelProgress.progressPercent)
            _animatedXPInLevel = State(initialValue: levelProgress.xpInCurrentLevel)
            _animatedXPNeeded = State(initialValue: levelProgress.xpNeededForNext)
            _animatedLevel = State(initialValue: levelProgress.currentLevel)
            _previousLevelState = State(initialValue: levelProgress.currentLevel)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let progressWidth = geometry.size.width * (animatedProgress / 100.0)
            
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#9CA3AF").opacity(0.3))
                
                // Animated progress fill - orange with glow
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#FF9500"))
                    .frame(width: max(progressWidth, 0))
                    .shadow(
                        color: Color(hex: "#FF9500").opacity(glowOpacity * 0.6),
                        radius: 8,
                        x: 0,
                        y: 0
                    )
                    .animation(.easeOut(duration: 0.3), value: progressWidth)
                
                // Level text on left and XP text on right
                HStack {
                    // Level label on the left - animated with scale on level change
                    if isLoading {
                        Text("LV.1")
                            .font(.caption)
                            .foregroundColor(.white)
                            .shimmer()
                    } else {
                        HStack(spacing: 0) {
                            Text("LV.")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text("\(animatedLevel)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                                .scaleEffect(levelScale)
                        }
                    }
                    
                    Spacer()
                    
                    // XP text on the right with animated numbers
                    if isLoading {
                        Text("0/0xp")
                            .font(.caption)
                            .foregroundColor(.white)
                            .shimmer()
                    } else {
                        HStack(spacing: 0) {
                            AnimatedNumberText(value: animatedXPInLevel, baseColor: .white)
                                .font(.caption)
                            Text("/")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text("\(animatedXPNeeded)")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text("xp")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .onChange(of: levelProgress.currentLevel) { oldLevel, newLevel in
            // Only animate if not in initial animation phase
            if newLevel != oldLevel && (!shouldAnimate || hasAnimated) {
                // Level changed - animate level number with scale pulse
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    levelScale = 1.3
                }
                
                // Update level number
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    animatedLevel = newLevel
                }
                
                // Reset scale
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        levelScale = 1.0
                    }
                }
                
                // Brief glow pulse on level change
                withAnimation(.easeOut(duration: 0.3)) {
                    glowOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        glowOpacity = 0.0
                    }
                }
            }
        }
        .onChange(of: levelProgress.progressPercent) { oldPercent, newPercent in
            // Only animate if not in initial animation phase
            if (!shouldAnimate || hasAnimated) {
                // Animate progress bar fill
                withAnimation(.easeOut(duration: 0.8)) {
                    animatedProgress = newPercent
                }
                
                // Brief glow pulse on XP gain
                if newPercent > oldPercent {
                    withAnimation(.easeOut(duration: 0.2)) {
                        glowOpacity = 0.5
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            glowOpacity = 0.0
                        }
                    }
                }
            }
        }
        .onChange(of: levelProgress.xpInCurrentLevel) { oldXP, newXP in
            // Only animate if not in initial animation phase
            if (!shouldAnimate || hasAnimated) {
                // Animate XP number counting
                let difference = abs(newXP - oldXP)
                let duration = min(0.6, Double(difference) * 0.02)
                
                withAnimation(.linear(duration: duration)) {
                    animatedXPInLevel = newXP
                }
            }
        }
        .onChange(of: levelProgress.xpNeededForNext) { oldNeeded, newNeeded in
            // Update needed XP (usually doesn't change, but handle it)
            animatedXPNeeded = newNeeded
        }
        .onAppear {
            if shouldAnimate && !hasAnimated {
                // Animate from previous values to new values
                hasAnimated = true
                
                // Small delay to ensure view is fully rendered
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Animate progress bar fill
                    withAnimation(.easeOut(duration: 0.8)) {
                        animatedProgress = levelProgress.progressPercent
                    }
                    
                    // Animate XP number counting
                    let difference = abs(levelProgress.xpInCurrentLevel - animatedXPInLevel)
                    let duration = min(0.8, Double(difference) * 0.02)
                    
                    withAnimation(.linear(duration: duration)) {
                        animatedXPInLevel = levelProgress.xpInCurrentLevel
                    }
                    
                    // Update XP needed
                    animatedXPNeeded = levelProgress.xpNeededForNext
                    
                    // Animate level change if needed
                    if levelProgress.currentLevel != animatedLevel {
                        // Level changed - animate level number with scale pulse
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            levelScale = 1.3
                        }
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            animatedLevel = levelProgress.currentLevel
                        }
                        
                        // Reset scale
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                levelScale = 1.0
                            }
                        }
                        
                        // Brief glow pulse on level change
                        withAnimation(.easeOut(duration: 0.3)) {
                            glowOpacity = 1.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                glowOpacity = 0.0
                            }
                        }
                    } else {
                        // Brief glow pulse on XP gain (no level change)
                        withAnimation(.easeOut(duration: 0.2)) {
                            glowOpacity = 0.5
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                glowOpacity = 0.0
                            }
                        }
                    }
                    
                    // Clear animation flag after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        // Clear the animation flag in progress manager
                        UserProgressManager.shared.shouldAnimateXPChange = false
                        UserProgressManager.shared.previousTotalXP = nil
                        UserProgressManager.shared.previousLevel = nil
                    }
                }
            } else {
                // Normal initialization (no animation)
                animatedProgress = levelProgress.progressPercent
                animatedXPInLevel = levelProgress.xpInCurrentLevel
                animatedXPNeeded = levelProgress.xpNeededForNext
                animatedLevel = levelProgress.currentLevel
                previousLevelState = levelProgress.currentLevel
            }
        }
    }
}


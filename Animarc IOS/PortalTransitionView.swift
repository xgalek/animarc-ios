//
//  PortalTransitionView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI
import UIKit

enum PortalTransitionPhase {
    case entry      // Phase 1: Darken over HomeView's portal
    case transition // Phase 2: Dark screen with particles
    case complete   // Finished - triggers navigation
}

// MARK: - Portal Transition Overlay
// This overlay appears ON TOP of HomeView, darkening over the existing portal

struct PortalTransitionOverlay: View {
    let onComplete: () -> Void
    
    @State private var currentPhase: PortalTransitionPhase = .entry
    @State private var darkOverlayOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textGlow: CGFloat = 0
    @State private var showParticles: Bool = false
    @State private var contentOpacity: Double = 1.0  // For fading out the entire phase 2 content
    
    var body: some View {
        ZStack {
            // Phase 1: Darkening overlay (fades from transparent to black)
            // This darkens OVER the existing HomeView portal
            if currentPhase == .entry {
                Color.black
                    .opacity(darkOverlayOpacity)
                    .ignoresSafeArea()
            }
            
            // Phase 2: Transition screen with particles
            if currentPhase == .transition {
                ZStack {
                    // Full black background (always visible)
                    Color.black
                        .ignoresSafeArea()
                    
                    // Content that fades out before navigation
                    ZStack {
                        // Particle system
                        if showParticles {
                            PortalParticleView()
                                .allowsHitTesting(false)
                        }
                        
                        // "Focus mode activated..." text
                        Text("Focus mode activated...")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .opacity(textOpacity)
                            .shadow(color: Color(hex: "#7FFF00").opacity(textGlow), radius: 20, x: 0, y: 0)
                    }
                    .opacity(contentOpacity)
                }
            }
        }
        .allowsHitTesting(false) // Don't block touches during transition
        .onAppear {
            startTransitionSequence()
        }
    }
    
    private func startTransitionSequence() {
        // Phase 1: Darken over HomeView's portal (2 seconds)
        // Haptic feedback at start
        let entryHaptic = UIImpactFeedbackGenerator(style: .medium)
        entryHaptic.impactOccurred()
        
        // Fade to black (darkening over the existing portal)
        withAnimation(.easeIn(duration: 2.0)) {
            darkOverlayOpacity = 1.0
        }
        
        // Phase 2: Transition Screen - starts at 2.0s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            currentPhase = .transition
            showParticles = true
            
            // Fade in text
            withAnimation(.easeIn(duration: 0.6)) {
                textOpacity = 1.0
            }
            
            // Gentle pulse animation for text glow
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                textGlow = 0.8
            }
        }
        
        // Fade out content smoothly before navigation - starts at 4.0s
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            // Smoothly fade out text, particles, and all content
            withAnimation(.easeOut(duration: 1.0)) {
                contentOpacity = 0.0
                textOpacity = 0.0
            }
        }
        
        // Complete and trigger navigation (5.5 seconds total)
        // Screen is now pure black after content faded out
        // FocusSessionView will handle the fade-reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            currentPhase = .complete
            onComplete()
        }
    }
}

// MARK: - Portal Particle System

struct PortalParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var rotation: Double
    var rotationSpeed: Double
    var opacity: Double = 1.0
    var size: CGFloat
    var isStar: Bool // true for star sparkles, false for glowing dots
    var color: Color
}

struct PortalParticleView: View {
    @State private var particles: [PortalParticle] = []
    @State private var timer: Timer?
    @State private var spawnTimer: Timer?
    @State private var startTime: Date = Date()
    
    private let particleColors = [
        Color(hex: "#7FFF00"), // Green portal color
        Color(hex: "#6FE4FF"), // Cyan
        Color(hex: "#F173FF"), // Magenta
        Color(hex: "#FFE66F"), // Yellow
        Color.white
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    if particle.isStar {
                        // Star sparkle shape
                        Image(systemName: "sparkle")
                            .font(.system(size: particle.size))
                            .foregroundColor(particle.color)
                            .position(particle.position)
                            .opacity(particle.opacity)
                            .rotationEffect(.degrees(particle.rotation))
                            .shadow(color: particle.color.opacity(0.8), radius: 4, x: 0, y: 0)
                    } else {
                        // Glowing dot
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        particle.color.opacity(0.9),
                                        particle.color.opacity(0.3)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: max(particle.size / 2, 2)
                                )
                            )
                            .frame(width: particle.size, height: particle.size)
                            .position(particle.position)
                            .opacity(particle.opacity)
                            .shadow(color: particle.color.opacity(0.6), radius: 8, x: 0, y: 0)
                    }
                }
            }
            .onAppear {
                startTime = Date()
                startSpawnTimer(in: geometry.size)
                startUpdateTimer(in: geometry.size)
            }
            .onDisappear {
                timer?.invalidate()
                spawnTimer?.invalidate()
            }
        }
    }
    
    private func startSpawnTimer(in size: CGSize) {
        // Spawn new particles every 0.1 seconds
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            spawnParticle(in: size)
        }
    }
    
    private func spawnParticle(in size: CGSize) {
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Stop spawning after 2.0 seconds
        if elapsed > 2.0 {
            spawnTimer?.invalidate()
            return
        }
        
        // Randomly decide if it's a star or dot (60% dots, 40% stars)
        let isStar = Double.random(in: 0...1) < 0.4
        
        // Random particle size
        let particleSize: CGFloat = isStar ? CGFloat.random(in: 8...16) : CGFloat.random(in: 4...10)
        
        // Random color from palette
        let color = particleColors.randomElement() ?? .white
        
        // Spawn from bottom half of screen, moving upward
        let startX = CGFloat.random(in: 0...size.width)
        let startY = CGFloat.random(in: size.height * 0.4...size.height)
        
        // Upward velocity with slight horizontal drift
        let horizontalDrift = Double.random(in: -30...30)
        let upwardSpeed = Double.random(in: 20...50)
        
        let particle = PortalParticle(
            position: CGPoint(x: startX, y: startY),
            velocity: CGVector(dx: horizontalDrift, dy: -upwardSpeed),
            rotation: Double.random(in: 0...360),
            rotationSpeed: Double.random(in: -90...90),
            size: particleSize,
            isStar: isStar,
            color: color
        )
        
        particles.append(particle)
    }
    
    private func startUpdateTimer(in size: CGSize) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateParticles(in: size)
        }
    }
    
    private func updateParticles(in size: CGSize) {
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Stop updating after 2.5 seconds
        if elapsed > 2.5 {
            timer?.invalidate()
            return
        }
        
        // Update each particle
        for i in particles.indices {
            // Update position
            particles[i].position.x += particles[i].velocity.dx * 0.016
            particles[i].position.y += particles[i].velocity.dy * 0.016
            
            // Update rotation
            particles[i].rotation += particles[i].rotationSpeed * 0.016
            
            // Fade out as particles rise
            let normalizedY = particles[i].position.y / size.height
            if normalizedY < 0.5 {
                // Start fading when particle reaches upper half
                let fadeProgress = (0.5 - normalizedY) / 0.5
                particles[i].opacity = 1.0 - fadeProgress
            }
        }
        
        // Remove particles that are off-screen or fully faded
        particles = particles.filter { particle in
            particle.position.y > -50 &&
            particle.position.y < size.height + 50 &&
            particle.position.x > -50 &&
            particle.position.x < size.width + 50 &&
            particle.opacity > 0.01
        }
    }
}

// MARK: - Exit Transition Overlay
// This overlay appears ON TOP of FocusSessionView, fading the parallax world to black

struct ExitTransitionOverlay: View {
    let onComplete: () -> Void
    
    @State private var darkOverlayOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Fade parallax world to black
            Color.black
                .opacity(darkOverlayOpacity)
                .ignoresSafeArea()
        }
        .allowsHitTesting(false) // Don't block touches during transition
        .onAppear {
            startTransitionSequence()
        }
    }
    
    private func startTransitionSequence() {
        // Haptic feedback at start
        let exitHaptic = UIImpactFeedbackGenerator(style: .medium)
        exitHaptic.impactOccurred()
        
        // Fade to black (1 second, easeIn)
        withAnimation(.easeIn(duration: 1.0)) {
            darkOverlayOpacity = 1.0
        }
        
        // Complete and trigger navigation (1 second total)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onComplete()
        }
    }
}

#Preview {
    PortalTransitionOverlay {
        print("Transition complete!")
    }
}

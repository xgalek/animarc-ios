//
//  TypingTextView.swift
//  Animarc IOS
//
//  A view that displays text with a typing animation effect
//

import SwiftUI

struct TypingTextView: View {
    let fullText: String
    let typingSpeed: TimeInterval
    let onComplete: (() -> Void)?
    
    @State private var displayedText: String = ""
    @State private var currentIndex: Int = 0
    
    init(fullText: String, typingSpeed: TimeInterval = 0.04, onComplete: (() -> Void)? = nil) {
        self.fullText = fullText
        self.typingSpeed = typingSpeed
        self.onComplete = onComplete
    }
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                startTyping()
            }
    }
    
    private func startTyping() {
        guard currentIndex < fullText.count else {
            onComplete?()
            return
        }
        
        Task {
            while currentIndex < fullText.count {
                try? await Task.sleep(nanoseconds: UInt64(typingSpeed * 1_000_000_000))
                
                await MainActor.run {
                    let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
                    displayedText = String(fullText[..<fullText.index(after: index)])
                    currentIndex += 1
                }
            }
            
            // Animation complete
            await MainActor.run {
                onComplete?()
            }
        }
    }
}





//
//  LottieView.swift
//  Animarc IOS
//
//  Created for parallax background and character animations
//

import SwiftUI
import Lottie

struct LottiePlayerView: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode
    let speed: CGFloat
    
    init(name: String, loopMode: LottieLoopMode = .loop, speed: CGFloat = 1.0) {
        self.name = name
        self.loopMode = loopMode
        self.speed = speed
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: .zero)
        
        // Use Lottie's LottieAnimationView
        let animationView = Lottie.LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed
        animationView.play()
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: containerView.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            animationView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Animation is already playing, no updates needed
    }
}

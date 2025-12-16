//
//  ContentView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showPortalTransition = false
    
    var body: some View {
        HomeView(
            showPortalTransition: $showPortalTransition,
            onPortalTransitionComplete: { _ in }
        )
    }
}

#Preview {
    ContentView()
}

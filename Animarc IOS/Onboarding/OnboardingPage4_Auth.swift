//
//  OnboardingPage4_Auth.swift
//  Animarc IOS
//
//  Page 4: Authentication (Sign Up/Sign In)
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift
import CryptoKit

struct OnboardingPage4_Auth: View {
    @Binding var currentPage: Int
    @Binding var savedUsername: String
    let onComplete: () -> Void
    
    @EnvironmentObject var progressManager: UserProgressManager
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var isLoading = false
    @State private var loadingMessage = ""
    @State private var contentAppeared = false
    
    var body: some View {
        ZStack {
            // Dark navy background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Spacer()
                    .frame(height: 60) // Top spacer after safe area
                
                // App name
                Text("Animarc")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : -20)
                    .animation(.easeOut(duration: 0.6), value: contentAppeared)
                
                // Tagline
                Text("Level up your focus")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : -20)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: contentAppeared)
                
                Spacer()
                
                // Sign in buttons section
                VStack(spacing: 16) {
                    // Email TextField
                    ZStack(alignment: .leading) {
                        if email.isEmpty {
                            Text("Email")
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .padding(.horizontal, 16)
                        }
                        TextField("", text: $email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                    }
                    .frame(height: 50)
                    .background(Color(hex: "#2A3441"))
                    .cornerRadius(8)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: contentAppeared)
                    
                    // Password SecureField
                    ZStack(alignment: .leading) {
                        if password.isEmpty {
                            Text("Password")
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .padding(.horizontal, 16)
                        }
                        SecureField("", text: $password)
                            .textContentType(isSignUpMode ? .newPassword : .password)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                    }
                    .frame(height: 50)
                    .background(Color(hex: "#2A3441"))
                    .cornerRadius(8)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: contentAppeared)
                    
                    // Sign In/Sign Up button
                    Button(action: {
                        if isSignUpMode {
                            handleEmailSignUp()
                        } else {
                            handleEmailSignIn()
                        }
                    }) {
                        Text(isSignUpMode ? "Sign Up" : "Sign In")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "#4ADE80"))
                            .cornerRadius(8)
                    }
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.6 : 1.0)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: contentAppeared)
                    
                    // Toggle sign in/sign up mode
                    Button(action: {
                        isSignUpMode.toggle()
                    }) {
                        Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                    .padding(.top, 4)
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.6 : 1.0)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: contentAppeared)
                    
                    // Divider with "or" text
                    HStack {
                        Rectangle()
                            .fill(Color(hex: "#9CA3AF").opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .padding(.horizontal, 12)
                        Rectangle()
                            .fill(Color(hex: "#9CA3AF").opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 8)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: contentAppeared)
                    
                    // Sign in with Apple button
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleSignInResult(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(8)
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.6 : 1.0)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.7), value: contentAppeared)
                    
                    // Sign in with Google button
                    Button(action: {
                        handleGoogleSignIn()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                            Text("Sign in with Google")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.6 : 1.0)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: contentAppeared)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                
                // Page indicator dots
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                }
                .padding(.bottom, 34) // Safe area bottom
            }
            
            // Loading overlay
            if isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.3)
                        
                        Text(loadingMessage)
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .padding(32)
                    .background(Color(hex: "#2A3441"))
                    .cornerRadius(16)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                contentAppeared = true
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let identityToken = appleIDCredential.identityToken,
                      let idTokenString = String(data: identityToken, encoding: .utf8) else {
                    errorMessage = "Failed to extract identity token. Please try again."
                    showError = true
                    return
                }
                
                Task { @MainActor in
                    isLoading = true
                    loadingMessage = "Connecting with Apple..."
                    
                    do {
                        let session = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                            credentials: .init(provider: .apple, idToken: idTokenString)
                        )
                        
                        isLoading = false
                        await handleAuthSuccess()
                    } catch {
                        isLoading = false
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
            
        case .failure(let error):
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    private func handleGoogleSignIn() {
        isLoading = true
        loadingMessage = "Connecting with Google..."
        
        let rawNonce = randomNonceString()
        let hashedNonce = sha256(rawNonce)
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: "443436294835-qgd6v7m2nov13rl2624eala6inr0scp1.apps.googleusercontent.com"
        )
        
        guard let rootViewController = getRootViewController() else {
            isLoading = false
            errorMessage = "Unable to get root view controller"
            showError = true
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: nil, nonce: hashedNonce) { result, error in
            if let error = error {
                Task { @MainActor in
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
                return
            }
            
            guard let result = result,
                  let idToken = result.user.idToken?.tokenString else {
                Task { @MainActor in
                    isLoading = false
                    errorMessage = "Failed to get ID token from Google"
                    showError = true
                }
                return
            }
            
            Task {
                do {
                    let session = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                        credentials: .init(provider: .google, idToken: idToken, nonce: rawNonce)
                    )
                    
                    await MainActor.run {
                        isLoading = false
                        handleAuthSuccess()
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
    }
    
    private func handleEmailSignIn() {
        isLoading = true
        loadingMessage = "Signing in..."
        
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    handleAuthSuccess()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func handleEmailSignUp() {
        isLoading = true
        loadingMessage = "Creating account..."
        
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signUp(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    handleAuthSuccess()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    @MainActor
    private func handleAuthSuccess() {
        // Set authenticated state
        SupabaseManager.shared.isAuthenticated = true
        
        // Save username if we have one
        if !savedUsername.isEmpty {
            Task {
                await saveUsername()
            }
        } else {
            // No username to save, just complete onboarding
            completeOnboarding()
        }
    }
    
    private func saveUsername() async {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
            // If we can't get userId, just complete onboarding
            await MainActor.run {
                completeOnboarding()
            }
            return
        }
        
        do {
            let updatedProgress = try await SupabaseManager.shared.updateDisplayName(
                userId: userId,
                newName: savedUsername
            )
            
            await MainActor.run {
                progressManager.userProgress = updatedProgress
                
                // Success haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                completeOnboarding()
            }
        } catch {
            print("OnboardingPage4_Auth: Failed to save username: \(error)")
            // Even if username save fails, complete onboarding
            await MainActor.run {
                completeOnboarding()
            }
        }
    }
    
    private func completeOnboarding() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Trigger completion callback
        onComplete()
    }
}

#Preview {
    OnboardingPage4_Auth(
        currentPage: .constant(3),
        savedUsername: .constant("TestUser"),
        onComplete: {}
    )
    .environmentObject(UserProgressManager.shared)
}




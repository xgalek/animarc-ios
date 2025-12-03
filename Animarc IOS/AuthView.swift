//
//  AuthView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 12/3/25.
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift
import CryptoKit

struct AuthView: View {
    @Binding var isAuthenticated: Bool
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Dark navy background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Spacer()
                
                // App name
                Text("Animarc")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                // Tagline
                Text("Level up your focus")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                
                Spacer()
                
                // Sign in buttons section
                VStack(spacing: 16) {
                    // Sign in with Apple button
                    SignInWithAppleButton(.signIn) { request in
                        // Request full name and email
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleSignInResult(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(8)
                    
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
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
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
                // Extract user information
                let userIdentifier = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName
                
                // Debug logging
                print("=== Apple Sign In Success ===")
                print("User ID: \(userIdentifier)")
                
                if let email = email {
                    print("Email: \(email)")
                }
                
                if let fullName = fullName {
                    let givenName = fullName.givenName ?? ""
                    let familyName = fullName.familyName ?? ""
                    print("Full Name: \(givenName) \(familyName)")
                }
                
                // Extract identity token for Supabase
                guard let identityToken = appleIDCredential.identityToken,
                      let idTokenString = String(data: identityToken, encoding: .utf8) else {
                    print("Error: Failed to extract identity token")
                    errorMessage = "Failed to extract identity token. Please try again."
                    showError = true
                    return
                }
                
                // Sign in with Supabase using Apple identity token
                Task {
                    do {
                        let session = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                            credentials: .init(provider: .apple, idToken: idTokenString)
                        )
                        
                        print("=== Supabase Sign In Success ===")
                        print("Supabase User ID: \(session.user.id)")
                        print("Supabase Email: \(session.user.email ?? "N/A")")
                        print("Session expires at: \(session.expiresAt)")
                        print("=================================")
                        
                        // Set authenticated state
                        await MainActor.run {
                            SupabaseManager.shared.isAuthenticated = true
                        }
                    } catch {
                        print("Supabase Sign In Error: \(error.localizedDescription)")
                        await MainActor.run {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            }
            
        case .failure(let error):
            print("Apple Sign In Error: \(error.localizedDescription)")
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
    
    // Generate a random nonce string
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
    
    // SHA256 hash of the nonce for Google Sign In
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    private func handleGoogleSignIn() {
        // Generate a random nonce for security validation
        let rawNonce = randomNonceString()
        let hashedNonce = sha256(rawNonce)
        
        // Configure Google Sign In with the hashed nonce
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: "443436294835-qgd6v7m2nov13rl2624eala6inr0scp1.apps.googleusercontent.com"
        )
        
        // Get root view controller
        guard let rootViewController = getRootViewController() else {
            errorMessage = "Unable to get root view controller"
            showError = true
            return
        }
        
        // Perform Google Sign In with nonce hint
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: nil, nonce: hashedNonce) { result, error in
            if let error = error {
                print("Google Sign In Error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showError = true
                return
            }
            
            guard let result = result,
                  let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get ID token from Google"
                showError = true
                return
            }
            
            // Sign in with Supabase using the RAW nonce (not hashed)
            Task {
                do {
                    let session = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                        credentials: .init(provider: .google, idToken: idToken, nonce: rawNonce)
                    )
                    
                    print("=== Supabase Google Sign In Success ===")
                    print("Supabase User ID: \(session.user.id)")
                    print("Supabase Email: \(session.user.email ?? "N/A")")
                    print("========================================")
                    
                    await MainActor.run {
                        SupabaseManager.shared.isAuthenticated = true
                    }
                } catch {
                    print("Supabase Google Sign In Error: \(error.localizedDescription)")
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
    }
}

#Preview {
    AuthView(isAuthenticated: .constant(false))
}


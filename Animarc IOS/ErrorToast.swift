//
//  ErrorToast.swift
//  Animarc IOS
//
//  Custom toast/banner component for displaying non-blocking error messages
//

import SwiftUI

enum ToastSeverity {
    case error
    case warning
    case success
    case info
    
    var color: Color {
        switch self {
        case .error:
            return Color(hex: "#DC2626")
        case .warning:
            return Color(hex: "#F59E0B")
        case .success:
            return Color(hex: "#22C55E")
        case .info:
            return Color(hex: "#3B82F6")
        }
    }
    
    var icon: String {
        switch self {
        case .error:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "exclamationmark.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}

struct ToastMessage: Identifiable {
    let id = UUID()
    let message: String
    let severity: ToastSeverity
    let duration: TimeInterval
    
    init(_ message: String, severity: ToastSeverity = .error, duration: TimeInterval = 4.0) {
        self.message = message
        self.severity = severity
        self.duration = duration
    }
}

struct ErrorToast: View {
    let message: ToastMessage
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -200
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: message.severity.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(message.message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(message.severity.color)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                offset = 0
                opacity = 1
            }
            
            // Auto-dismiss after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + message.duration) {
                dismiss()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -50 {
                        dismiss()
                    }
                }
        )
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = -200
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

struct ToastModifier: ViewModifier {
    @ObservedObject var errorManager: ErrorManager
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let currentToast = errorManager.currentToast {
                ErrorToast(message: currentToast) {
                    errorManager.dismissCurrentToast()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1000)
                .padding(.top, 8)
            }
        }
    }
}

extension View {
    func toast(errorManager: ErrorManager) -> some View {
        modifier(ToastModifier(errorManager: errorManager))
    }
}









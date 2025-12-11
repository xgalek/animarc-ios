//
//  ErrorManager.swift
//  Animarc IOS
//
//  Centralized error handling and toast notification manager
//

import Foundation
import SwiftUI

@MainActor
final class ErrorManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ErrorManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var currentToast: ToastMessage?
    @Published private(set) var errorQueue: [ToastMessage] = []
    
    // MARK: - Private Properties
    
    private var dismissTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Show an error toast message
    func showError(_ message: String, duration: TimeInterval = 4.0) {
        showToast(ToastMessage(message, severity: .error, duration: duration))
    }
    
    /// Show a warning toast message
    func showWarning(_ message: String, duration: TimeInterval = 4.0) {
        showToast(ToastMessage(message, severity: .warning, duration: duration))
    }
    
    /// Show a success toast message
    func showSuccess(_ message: String, duration: TimeInterval = 3.0) {
        showToast(ToastMessage(message, severity: .success, duration: duration))
    }
    
    /// Show an info toast message
    func showInfo(_ message: String, duration: TimeInterval = 3.0) {
        showToast(ToastMessage(message, severity: .info, duration: duration))
    }
    
    /// Show a toast from an Error
    func showError(_ error: Error, duration: TimeInterval = 4.0) {
        let message: String
        if let localizedError = error as? LocalizedError {
            message = localizedError.errorDescription ?? error.localizedDescription
        } else {
            message = error.localizedDescription
        }
        showError(message, duration: duration)
    }
    
    /// Dismiss the current toast
    func dismissCurrentToast() {
        dismissTask?.cancel()
        currentToast = nil
        
        // Show next toast in queue if available
        if !errorQueue.isEmpty {
            let nextToast = errorQueue.removeFirst()
            showToastImmediate(nextToast)
        }
    }
    
    // MARK: - Private Methods
    
    private func showToast(_ toast: ToastMessage) {
        // If there's already a toast showing, queue this one
        if currentToast != nil {
            errorQueue.append(toast)
            return
        }
        
        showToastImmediate(toast)
    }
    
    private func showToastImmediate(_ toast: ToastMessage) {
        currentToast = toast
        
        // Auto-dismiss after duration
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(toast.duration * 1_000_000_000))
            if !Task.isCancelled {
                await MainActor.run {
                    dismissCurrentToast()
                }
            }
        }
    }
}




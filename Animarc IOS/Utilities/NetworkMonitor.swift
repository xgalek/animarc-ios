//
//  NetworkMonitor.swift
//  Animarc IOS
//
//  Network connectivity monitoring utility
//

import Foundation
import Network
import SwiftUI

@MainActor
final class NetworkMonitor: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = NetworkMonitor()
    
    // MARK: - Published Properties
    
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: NWInterface.InterfaceType?
    
    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // MARK: - Initialization
    
    private init() {
        startMonitoring()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    /// Check if network is available before making a request
    func checkConnection() -> Bool {
        return isConnected
    }
}




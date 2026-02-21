//
//  FocusMusicManager.swift
//  Animarc IOS
//
//  Manager for handling focus music and home music playback
//

import Foundation
import AVFoundation
import Combine
import SwiftUI

/// Observable singleton manager for focus and home music playback
@MainActor
final class FocusMusicManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = FocusMusicManager()
    
    // MARK: - Published Properties - Focus Music
    
    /// Whether focus music is enabled in settings
    @Published var focusMusicEnabled: Bool = false
    
    /// Whether focus music is currently playing
    @Published var focusMusicPlaying: Bool = false
    
    /// Currently selected focus music track
    @Published var focusMusicTrack: FocusMusicTrack?
    
    /// Focus music volume (0.0 to 1.0)
    @Published var focusMusicVolume: Float = 0.5
    
    // MARK: - Published Properties - Home Music
    
    /// Whether home music is enabled in settings
    @Published var homeMusicEnabled: Bool = false
    
    /// Whether home music is currently playing
    @Published var homeMusicPlaying: Bool = false
    
    /// Currently selected home music track
    @Published var homeMusicTrack: FocusMusicTrack?
    
    /// Home music volume (0.0 to 1.0)
    @Published var homeMusicVolume: Float = 0.5
    
    // MARK: - Available Tracks
    
    /// All available music tracks
    let availableTracks: [FocusMusicTrack] = [
        FocusMusicTrack(
            id: "soft_focus",
            name: "Soft Focus",
            filename: "soft-focus-ambient-for-calm-work-sessions-457309"
        ),
        FocusMusicTrack(
            id: "study_music",
            name: "Study Music",
            filename: "study-music-for-focus-and-brain-power-432-hz-172844"
        ),
        FocusMusicTrack(
            id: "cozy_lofi",
            name: "Cozy LoFi",
            filename: "cozy-lofi-background-music-457199"
        ),
        FocusMusicTrack(
            id: "lofi_dreams",
            name: "LoFi Dreams",
            filename: "lofidreams-lofi-background-music-336230"
        ),
        FocusMusicTrack(
            id: "lofi_girl",
            name: "LoFi Girl",
            filename: "lofidreams-lofi-girl-lofi-ambient-music-365952"
        ),
        FocusMusicTrack(
            id: "peaceful_piano",
            name: "Peaceful Piano",
            filename: "nickpanek-peaceful-piano-instrumental-for-studying-and-focus-232535"
        ),
        FocusMusicTrack(
            id: "mountain_piano",
            name: "Mountain Piano",
            filename: "the_mountain-piano-background-141480"
        ),
        FocusMusicTrack(
            id: "mountain_music",
            name: "Mountain Music",
            filename: "the_mountain-piano-background-music-487020"
        ),
    ]
    
    // MARK: - Private Properties
    
    private var focusPlayer: AVAudioPlayer?
    private var homePlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    
    // MARK: - Initialization
    
    private init() {
        setupAudioSession()
        loadSettings()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("❌ FocusMusicManager: Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Settings Persistence
    
    private func loadSettings() {
        // Load Focus Music settings (default to ON)
        // Check if key exists - if not, default to true for first-time users
        if UserDefaults.standard.object(forKey: "focusMusicEnabled") != nil {
            focusMusicEnabled = UserDefaults.standard.bool(forKey: "focusMusicEnabled")
        } else {
            focusMusicEnabled = true // Default ON
            UserDefaults.standard.set(true, forKey: "focusMusicEnabled")
        }
        
        focusMusicVolume = UserDefaults.standard.object(forKey: "focusMusicVolume") as? Float ?? 0.5
        
        if let savedTrackId = UserDefaults.standard.string(forKey: "focusMusicTrackId"),
           let track = availableTracks.first(where: { $0.id == savedTrackId }) {
            focusMusicTrack = track
        } else {
            // Default Focus Music to "Study Music" (second track, index 1)
            // Fallback to first track if Study Music doesn't exist
            focusMusicTrack = availableTracks.count > 1 ? availableTracks[1] : availableTracks.first
            // Save the default selection
            if let defaultTrack = focusMusicTrack {
                UserDefaults.standard.set(defaultTrack.id, forKey: "focusMusicTrackId")
            }
        }
        
        // Load Home Music settings (default to ON)
        // Check if key exists - if not, default to true for first-time users
        if UserDefaults.standard.object(forKey: "homeMusicEnabled") != nil {
            homeMusicEnabled = UserDefaults.standard.bool(forKey: "homeMusicEnabled")
        } else {
            homeMusicEnabled = true // Default ON
            UserDefaults.standard.set(true, forKey: "homeMusicEnabled")
        }
        
        homeMusicVolume = UserDefaults.standard.object(forKey: "homeMusicVolume") as? Float ?? 0.5
        
        if let savedTrackId = UserDefaults.standard.string(forKey: "homeMusicTrackId"),
           let track = availableTracks.first(where: { $0.id == savedTrackId }) {
            homeMusicTrack = track
        } else {
            // Default Home Music to "Soft Focus" (first track, index 0)
            homeMusicTrack = availableTracks.first
            // Save the default selection
            if let defaultTrack = homeMusicTrack {
                UserDefaults.standard.set(defaultTrack.id, forKey: "homeMusicTrackId")
            }
        }
    }
    
    // MARK: - Focus Music Methods
    
    /// Start playing focus music with optional track selection
    func startFocusMusic(track: FocusMusicTrack? = nil) {
        guard focusMusicEnabled else {
            print("ℹ️ FocusMusicManager: Focus music is disabled, not starting")
            return
        }
        
        let trackToPlay = track ?? focusMusicTrack ?? availableTracks.first
        guard let trackToPlay = trackToPlay else {
            print("❌ FocusMusicManager: No track available to play")
            return
        }
        
        guard let url = Bundle.main.url(forResource: trackToPlay.filename, withExtension: "mp3") else {
            print("❌ FocusMusicManager: Could not find focus music file: \(trackToPlay.filename).mp3")
            return
        }
        
        do {
            stopFocusMusic()
            
            focusPlayer = try AVAudioPlayer(contentsOf: url)
            focusPlayer?.numberOfLoops = -1 // Loop indefinitely
            focusPlayer?.volume = focusMusicVolume
            focusPlayer?.prepareToPlay()
            focusPlayer?.play()
            
            focusMusicTrack = trackToPlay
            focusMusicPlaying = true
            
            UserDefaults.standard.set(trackToPlay.id, forKey: "focusMusicTrackId")
            
            print("✅ FocusMusicManager: Started playing focus music: \(trackToPlay.name)")
        } catch {
            print("❌ FocusMusicManager: Failed to play focus music: \(error)")
        }
    }
    
    /// Stop focus music playback
    func stopFocusMusic() {
        focusPlayer?.stop()
        focusPlayer = nil
        focusMusicPlaying = false
        print("⏹️ FocusMusicManager: Stopped focus music")
    }
    
    /// Pause focus music playback
    func pauseFocusMusic() {
        focusPlayer?.pause()
        focusMusicPlaying = false
        print("⏸️ FocusMusicManager: Paused focus music")
    }
    
    /// Resume focus music playback
    func resumeFocusMusic() {
        guard focusMusicEnabled else {
            print("ℹ️ FocusMusicManager: Focus music is disabled, cannot resume")
            return
        }
        
        guard let player = focusPlayer else {
            // If no player exists, start fresh
            startFocusMusic()
            return
        }
        
        player.play()
        focusMusicPlaying = true
        print("▶️ FocusMusicManager: Resumed focus music")
    }
    
    /// Enable or disable focus music
    func setFocusMusicEnabled(_ enabled: Bool) {
        focusMusicEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "focusMusicEnabled")
        
        if !enabled {
            stopFocusMusic()
        }
        
        print("🔧 FocusMusicManager: Focus music \(enabled ? "enabled" : "disabled")")
    }
    
    /// Set focus music volume (0.0 to 1.0)
    func setFocusMusicVolume(_ volume: Float) {
        let clamped = max(0.0, min(1.0, volume))
        focusMusicVolume = clamped
        focusPlayer?.volume = clamped
        UserDefaults.standard.set(clamped, forKey: "focusMusicVolume")
    }
    
    /// Select a focus music track
    func selectFocusMusicTrack(_ track: FocusMusicTrack) {
        focusMusicTrack = track
        UserDefaults.standard.set(track.id, forKey: "focusMusicTrackId")
        
        // If currently playing, switch to new track
        if focusMusicPlaying {
            startFocusMusic(track: track)
        }
        
        print("🎵 FocusMusicManager: Selected focus music track: \(track.name)")
    }
    
    /// Cycle to the next focus music track
    func nextFocusMusicTrack() {
        guard let currentTrack = focusMusicTrack,
              let currentIndex = availableTracks.firstIndex(where: { $0.id == currentTrack.id }) else {
            // If no current track, select first
            if let firstTrack = availableTracks.first {
                selectFocusMusicTrack(firstTrack)
                if focusMusicEnabled {
                    startFocusMusic(track: firstTrack)
                }
            }
            return
        }
        
        // Get next track (wrap around)
        let nextIndex = (currentIndex + 1) % availableTracks.count
        let nextTrack = availableTracks[nextIndex]
        
        selectFocusMusicTrack(nextTrack)
        
        // If music is enabled, start playing the new track
        if focusMusicEnabled {
            startFocusMusic(track: nextTrack)
        }
        
        print("⏭️ FocusMusicManager: Switched to next track: \(nextTrack.name)")
    }
    
    func previousFocusMusicTrack() {
        guard let currentTrack = focusMusicTrack,
              let currentIndex = availableTracks.firstIndex(where: { $0.id == currentTrack.id }) else {
            if let lastTrack = availableTracks.last {
                selectFocusMusicTrack(lastTrack)
                if focusMusicEnabled {
                    startFocusMusic(track: lastTrack)
                }
            }
            return
        }
        
        let prevIndex = (currentIndex - 1 + availableTracks.count) % availableTracks.count
        let prevTrack = availableTracks[prevIndex]
        
        selectFocusMusicTrack(prevTrack)
        
        if focusMusicEnabled {
            startFocusMusic(track: prevTrack)
        }
        
        print("⏮️ FocusMusicManager: Switched to previous track: \(prevTrack.name)")
    }
    
    // MARK: - Home Music Methods
    
    /// Start playing home music with optional track selection
    func startHomeMusic(track: FocusMusicTrack? = nil) {
        guard homeMusicEnabled else {
            print("ℹ️ FocusMusicManager: Home music is disabled, not starting")
            return
        }
        
        let trackToPlay = track ?? homeMusicTrack ?? availableTracks.first
        guard let trackToPlay = trackToPlay else {
            print("❌ FocusMusicManager: No track available to play")
            return
        }
        
        guard let url = Bundle.main.url(forResource: trackToPlay.filename, withExtension: "mp3") else {
            print("❌ FocusMusicManager: Could not find home music file: \(trackToPlay.filename).mp3")
            return
        }
        
        do {
            stopHomeMusic()
            
            homePlayer = try AVAudioPlayer(contentsOf: url)
            homePlayer?.numberOfLoops = -1 // Loop indefinitely
            homePlayer?.volume = homeMusicVolume
            homePlayer?.prepareToPlay()
            homePlayer?.play()
            
            homeMusicTrack = trackToPlay
            homeMusicPlaying = true
            
            UserDefaults.standard.set(trackToPlay.id, forKey: "homeMusicTrackId")
            
            print("✅ FocusMusicManager: Started playing home music: \(trackToPlay.name)")
        } catch {
            print("❌ FocusMusicManager: Failed to play home music: \(error)")
        }
    }
    
    /// Stop home music playback
    func stopHomeMusic() {
        homePlayer?.stop()
        homePlayer = nil
        homeMusicPlaying = false
        print("⏹️ FocusMusicManager: Stopped home music")
    }
    
    /// Pause home music playback
    func pauseHomeMusic() {
        homePlayer?.pause()
        homeMusicPlaying = false
        print("⏸️ FocusMusicManager: Paused home music")
    }
    
    /// Resume home music playback
    func resumeHomeMusic() {
        guard homeMusicEnabled else {
            print("ℹ️ FocusMusicManager: Home music is disabled, cannot resume")
            return
        }
        
        guard let player = homePlayer else {
            // If no player exists, start fresh
            startHomeMusic()
            return
        }
        
        player.play()
        homeMusicPlaying = true
        print("▶️ FocusMusicManager: Resumed home music")
    }
    
    /// Enable or disable home music
    func setHomeMusicEnabled(_ enabled: Bool) {
        homeMusicEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "homeMusicEnabled")
        
        if !enabled {
            stopHomeMusic()
        }
        
        print("🔧 FocusMusicManager: Home music \(enabled ? "enabled" : "disabled")")
    }
    
    /// Set home music volume (0.0 to 1.0)
    func setHomeMusicVolume(_ volume: Float) {
        let clamped = max(0.0, min(1.0, volume))
        homeMusicVolume = clamped
        homePlayer?.volume = clamped
        UserDefaults.standard.set(clamped, forKey: "homeMusicVolume")
    }
    
    /// Select a home music track
    func selectHomeMusicTrack(_ track: FocusMusicTrack) {
        homeMusicTrack = track
        UserDefaults.standard.set(track.id, forKey: "homeMusicTrackId")
        
        // If currently playing, switch to new track
        if homeMusicPlaying {
            startHomeMusic(track: track)
        }
        
        print("🎵 FocusMusicManager: Selected home music track: \(track.name)")
    }
}

// MARK: - Focus Music Track Model

struct FocusMusicTrack: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let filename: String
}


//
//  AudioPlayer.swift
//  AudioRecorder
//
//  Created by Apple on 22/06/24.
//

import Foundation
import AVFoundation

/// Protocol defining the interface for audio playback operations.
protocol AudioPlaying: AnyObject {
    /// Delegate to receive audio player related events.
    var delegate: AudioPlayerDelegate? { get set }
    
    /// Plays the audio recording located at the specified URL.
    ///
    /// - Parameter url: The URL of the audio recording to play.
    func playRecording(url: URL)
    
    /// Stops the currently playing audio.
    func stopPlaying()
    
    /// Pauses the currently playing audio.
    func pausePlaying()
    
    /// Resumes playback from a paused state.
    func resumePlaying()
}

/// Protocol for receiving audio player related events.
protocol AudioPlayerDelegate: AnyObject {
    /// Notifies the delegate when audio playback has finished.
    ///
    /// - Parameter success: `true` if playback finished successfully; `false` otherwise.
    func didFinishPlaying(success: Bool)
    
    /// Notifies the delegate of the current playback time and total duration during playback.
    ///
    /// - Parameters:
    ///   - currentTime: The current playback time in seconds.
    ///   - duration: The total duration of the audio file being played.
    func updatePlaybackTime(currentTime: TimeInterval, duration: TimeInterval)
}

/// Manages audio playback using AVAudioPlayer with additional functionalities.
final class AudioPlayer: NSObject, AudioPlaying {
    
    // MARK: - Properties
     
    /// Delegate to receive audio player related events.
    weak var delegate: AudioPlayerDelegate?
    
    private var audioPlayer: AVAudioPlayer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0.0
    private var timer: Timer?
    
    private var isPlaying = false
    
    /// Initializes the audio player.
    override init() {
        super.init()
    }
    
    // MARK: - Audio Playback Operations
    
    /// Plays the audio recording located at the specified URL.
    ///
    /// This function starts playing the audio using AVAudioPlayer, sets up necessary playback settings,
    /// and begins emitting timer updates for playback progress.
    ///
    /// - Parameter url: The URL of the audio recording to play.
    func playRecording(url: URL) {
        guard !isPlaying else {
            stopPlaying()
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            
            startTimer()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
            self.delegate?.didFinishPlaying(success: false)
        }
    }
    
    /// Stops the ongoing audio playback.
    ///
    /// This function stops the AVAudioPlayer, invalidates the playback timer, and notifies the delegate
    /// of the playback completion status.
    func stopPlaying() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        stopTimer()
        delegate?.didFinishPlaying(success: true)
    }
    
    /// Pauses the ongoing audio playback.
    ///
    /// This function pauses the AVAudioPlayer and pauses the playback timer.
    func pausePlaying() {
        guard isPlaying else { return }
        audioPlayer?.pause()
        pausedTime = audioPlayer?.currentTime ?? 0.0
        stopTimer()
    }
    
    /// Resumes playback from a paused state.
    ///
    /// This function resumes audio playback from the paused state, restarts the playback timer,
    /// and resumes playback using AVAudioPlayer.
    func resumePlaying() {
        guard let player = audioPlayer, !isPlaying else { return }
        player.currentTime = pausedTime
        player.play()
        isPlaying = true
        startTimer()
    }
    
    // MARK: - Private Methods
    
    // Private methods like startTimer, stopTimer, audioPlayerDidFinishPlaying, audioPlayerDecodeErrorDidOccur, etc.,
    // have their implementation details already commented in the original code.
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let player = self?.audioPlayer else { return }
            self?.delegate?.updatePlaybackTime(currentTime: player.currentTime, duration: player.duration)
        }
        timer?.fire()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

// Extension for AVAudioPlayerDelegate methods and error handling.
extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.stopTimer()
        self.delegate?.didFinishPlaying(success: flag)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.stopTimer()
    }
}

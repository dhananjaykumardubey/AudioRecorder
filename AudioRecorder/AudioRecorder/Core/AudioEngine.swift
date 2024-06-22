//
//  AudioEngine.swift
//  AudioRecorder
//
//  Created by Apple on 22/06/24.
//

import Foundation
import AVFoundation
import UIKit

/// Handles audio recording using AVAudioEngine with additional functionalities.
final class AudioEngine: NSObject, AudioRecording {
    
    // MARK: Public Properties
    
    /// Delegate to receive audio recording related events.
    weak var delegate: AudioRecordingDelegate?
    
    /// URL of the current recording file.
    var _recordingURL: URL? {
        return recordingURL
    }
    
    // MARK: Private Properties
    private var recordingURL: URL?
    private var audioEngine: AVAudioEngine!
    private var audioFile: AVAudioFile?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0.0
    private var timer: Timer?
    private var isRecording = false
    private var isPaused = false
    private var isTerminating = false
    private let fileManager: AudioFileManager
    private var sessionQueue = DispatchQueue(label: "com.audioRecorder.sessionQueue")
    
    // MARK: Initialiser
    override init() {
        self.fileManager = AudioFileManager.shared
        super.init()
        setupAudioSession()
        setupNotifications()
    }
    
    deinit {
        print("deinit called")
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Audio Recording Operations
    
    /// Starts recording audio.
    ///
    /// This function begins audio recording using AVAudioEngine. It creates a new audio file,
    /// sets up necessary audio settings, and starts emitting timer updates for the recording duration.
    func startRecording() {
        sessionQueue.async {
            if !self.isRecording {
                self.isRecording = true
                self.pausedTime = 0
                self.recordingURL = nil
                do {
                    if let fileURL = self.fileManager.createNewAudioFile() {
                        self.recordingURL = fileURL
                        try self.setupAudioEngine(with: fileURL)
                        
                        // Start emitting timer updates
                        self.startTimer()
                        
                        self.audioEngine.prepare()
                        try self.audioEngine.start()
                    } else {
                        self.handleError(.fileInitialization("Failed to create new audio file"))
                    }
                } catch {
                    self.handleError(.fileInitialization(error.localizedDescription))
                }
            }
        }
    }
    
    /// Stops the ongoing audio recording.
    ///
    /// This function stops the AVAudioEngine, invalidates the recording timer, and notifies the delegate
    /// of the recording completion status.
    func stopRecording() {
        sessionQueue.async {
            if self.isRecording {
                self.isRecording = false
                self.stopTimer()
                
                self.audioEngine.stop()
                self.audioEngine.reset()
                
                if self.recordingURL != nil {
                    self.delegate?.didFinishRecording(success: true)
                }
            }
        }
    }
    
    /// Pauses the ongoing audio recording.
    ///
    /// This function pauses the AVAudioEngine and pauses the recording timer.
    func pauseRecording() {
        sessionQueue.async {
            if self.isRecording && !self.isPaused {
                self.pauseTimer()
                self.removeTapIfExists()
                self.audioEngine.pause()
                self.isPaused = true
            }
        }
    }
    
    /// Resumes a paused audio recording.
    ///
    /// This function resumes audio recording from a paused state, restarts the recording timer, and resumes
    /// recording using AVAudioEngine.
    func resumeRecording() {
        sessionQueue.async {
            if self.isRecording && self.isPaused {
                self.startTime = Date()
                self.startTimer()
                do {
                    self.removeTapIfExists()
                    try self.audioEngine.start()
                    self.isPaused = false
                } catch {
                    self.handleError(.audioSessionSetup(error.localizedDescription))
                }
            }
        }
    }
    
    // MARK: Private APIs
    private func removeTapIfExists() {
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers, .allowBluetooth, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            handleError(.audioSessionSetup(error.localizedDescription))
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange(notification:)), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    private func setupAudioEngine(with url: URL) throws {
      audioEngine = AVAudioEngine()

      let inputNode = audioEngine.inputNode
      let hwFormat = inputNode.outputFormat(forBus: 0)
      let audioSession = AVAudioSession.sharedInstance()
    var preferredSampleRate = audioSession.preferredSampleRate
      
      print("Preferred Sample Rate: \(preferredSampleRate)")
      print("Hardware Input Format Sample Rate: \(hwFormat.sampleRate)")

      // Handle 0.0 preferred sample rate first
      if preferredSampleRate == 0.0 {
          preferredSampleRate = 48000.0
          print("WARNING: Preferred sample rate was 0.0. Using default sample rate (44100 Hz).")
      }

      func configureAudioFormat(withRate rate: Double) throws -> AVAudioFormat {
        let format = AVAudioFormat(commonFormat: hwFormat.commonFormat, sampleRate: rate, channels: hwFormat.channelCount, interleaved: hwFormat.isInterleaved)
        guard let format = format else {
          print("Failed to create audio format")
          throw AudioRecorderError.audioFormatSetup("Failed to create audio format")
        }
        return format
      }

      // Check if preferred rate needs adjustment
      if preferredSampleRate != hwFormat.sampleRate {
        print("WARNING: Preferred sample rate doesn't match hardware format. Trying common rates.")
        let commonRates = [44100.0, 48000.0]
        for rate in commonRates {
          do {
            let format = try configureAudioFormat(withRate: rate)
            audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
              guard let self = self, let audioFile = self.audioFile else { return }
              do {
                try audioFile.write(from: buffer)
              } catch {
                self.handleError(.fileInitialization(error.localizedDescription))
              }
            }
            return
          } catch {
            print("Failed to set preferred sample rate to \(rate): \(error.localizedDescription)")
          }
        }
        // If all common rates fail, throw an error
        throw AudioRecorderError.audioSessionSetup("Failed to find compatible sample rate")
      }
      
      // Use the preferred rate (after potentially adjusting it)
      let format = try configureAudioFormat(withRate: preferredSampleRate)
      audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
      inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
        guard let self = self, let audioFile = self.audioFile else { return }
        do {
          try audioFile.write(from: buffer)
        } catch {
          self.handleError(.fileInitialization(error.localizedDescription))
        }
      }
    }

    
    @objc private func handleAppWillTerminate() {
        isTerminating = true
        stopRecording()
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            if isRecording {
                pauseRecording()
            }
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resumeRecording()
                }
            }
        default:
            break
        }
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            pauseRecording()
        default:
            break
        }
    }
    
    private func startTimer() {
        self.startTime = Date()
        // Invalidate existing timer before creating a new one
        self.timer?.invalidate()
        self.timer = nil
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else {
                print("Self or startTime is nil.")
                return
            }
            
            let currentTime = Date().timeIntervalSince(startTime) + self.pausedTime
            self.delegate?.recordingDuration(duration: currentTime.formattedTime)
        }
        
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
            print("Timer started.")
        } else {
            print("Timer creation failed.")
        }
        
        print("Delegate: \(String(describing: delegate))")
        print("startTime: \(String(describing: startTime))")
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        self.pausedTime = 0
        print("Timer stopped.")
    }
    
    private func pauseTimer() {
        timer?.invalidate()
        timer = nil
        if let startTime = startTime {
            pausedTime += Date().timeIntervalSince(startTime)
        }
        print("Timer Paused")
    }
    
    // Handles various errors that may occur during audio recording.
    private func handleError(_ error: AudioRecorderError) {
        // Handle errors here, e.g., logging, analytics, or UI feedback
        switch error {
        case .audioSessionSetup(let message):
            print("Audio Session Setup Error: \(message)")
        case .fileInitialization(let message):
            print("File Initialization Error: \(message)")
        case .audioFormatSetup(let message):
            print("Audio format set up error: \(message)")
        }
    }
}

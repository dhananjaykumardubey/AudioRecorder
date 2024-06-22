import AVFoundation
import UIKit

/// Protocol defining the interface for audio recording operations.
protocol AudioRecording: AnyObject {
    /// Delegate to receive audio recording related events.
    var delegate: AudioRecordingDelegate? { get set }
    
    /// The URL of the current recording file.
    var _recordingURL: URL? { get }
    
    /// Starts recording audio.
    func startRecording()
    
    /// Stops the ongoing recording.
    func stopRecording()
    
    /// Pauses the ongoing recording.
    func pauseRecording()
    
    /// Resumes a paused recording.
    func resumeRecording()
}

/// Protocol for receiving audio recording related events.
protocol AudioRecordingDelegate: AnyObject {
    /// Notifies the delegate when recording has finished.
    ///
    /// - Parameter success: `true` if recording finished successfully; `false` otherwise.
    func didFinishRecording(success: Bool)
    
    /// Notifies the delegate of the current duration of the ongoing recording.
    ///
    /// - Parameter duration: String representation of the current recording duration.
    func recordingDuration(duration: String)
}

/// Handles audio recording using AVAudioRecorder with additional functionalities.
final class AudioRecorder: NSObject, AudioRecording {
    
    // MARK: Public Properties
    
    /// Delegate to receive audio recording related events.
    weak var delegate: AudioRecordingDelegate?
    
    /// URL of the current recording file.
    var _recordingURL: URL? {
        return recordingURL
    }
    
    // MARK: Private Properties
    private var recordingURL: URL?
    private var audioRecorder: AVAudioRecorder?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0.0
    private var timer: Timer?
    private var isRecording = false
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
    /// This function begins audio recording using AVAudioRecorder. It creates a new audio file,
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
                        let settings: [String: Any] = [
                            AVFormatIDKey: kAudioFormatMPEG4AAC,
                            AVSampleRateKey: 44100.0,
                            AVNumberOfChannelsKey: 2,
                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                        ]
                        
                        self.audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
                        self.audioRecorder?.delegate = self
                        self.audioRecorder?.prepareToRecord()
                        self.audioRecorder?.record()
                        
                        // Start emitting timer updates
                        self.startTimer()
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
    /// This function stops the AVAudioRecorder, invalidates the recording timer, and notifies the delegate
    /// of the recording completion status.
    func stopRecording() {
        sessionQueue.async {
            if self.isRecording {
                self.isRecording = false
                self.stopTimer()
                
                self.audioRecorder?.stop()
                self.audioRecorder = nil
                
                if self.recordingURL != nil {
                    self.delegate?.didFinishRecording(success: true)
                }
            }
        }
    }
    
    /// Pauses the ongoing audio recording.
    ///
    /// This function pauses the AVAudioRecorder and pauses the recording timer.
    func pauseRecording() {
        sessionQueue.async {
            if self.isRecording {
                self.pauseTimer()
                self.audioRecorder?.pause()
            }
        }
    }
    
    /// Resumes a paused audio recording.
    ///
    /// This function resumes audio recording from a paused state, restarts the recording timer, and resumes
    /// recording using AVAudioRecorder.
    func resumeRecording() {
        sessionQueue.async {
            if self.isRecording {
                self.startTime = Date()
                self.startTimer()
                self.audioRecorder?.record()
            }
        }
    }
    
    // MARK: Private APIs
    
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
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            self.handleError(.fileInitialization("Recording did not finish successfully"))
        }
        self.delegate?.didFinishRecording(success: flag)
        stopTimer()
    }
}

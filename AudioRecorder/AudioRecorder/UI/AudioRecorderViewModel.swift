//
//  AudioRecorderViewModel.swift
//  AudioRecorder
//
//  Created by Apple on 22/06/24.
//

import Foundation
import Combine

/// Enum representing the states of audio recording.
enum RecordingState {
    /// Initial state when recording starts.
    case start
    
    /// State when recording is paused.
    case paused
    
    /// State when recording resumes from a paused state.
    case resume
    
    /// State when recording is stopped.
    case stop
}

/// Enum representing the states of audio playback.
enum PlayingState {
    /// State when audio is playing.
    case play
    
    /// State when audio playback is stopped.
    case stop
    
    /// Initial state when no audio is playing.
    case none
}


/// Protocol defining input actions for controlling audio recording and playback.
protocol AudioRecorderViewModelInputs {
    /// Binds necessary resources and prepares the view model for interaction.
    func bindViewModel()
    
    /// Initiates audio recording.
    func startRecording()
    
    /// Stops the ongoing audio recording.
    func stopRecording()
    
    /// Pauses the ongoing audio recording.
    func pauseRecording()
    
    /// Resumes the paused audio recording.
    func resumeRecording()
    
    /// Initiates playback of the recorded audio.
    func playRecording()
    
    /// Stops ongoing audio playback.
    func stopPlaying()
}

/// Protocol defining output data streams and state updates for audio recording and playback.
protocol AudioRecorderViewModelOutputs {
    /// Stream indicating whether audio recording is currently active.
    var isRecordingSubject: CurrentValueSubject<Bool, Never> { get }
    
    /// Stream indicating whether audio playback is currently active.
    var isPlayingSubject: CurrentValueSubject<Bool, Never> { get }
    
    /// Stream providing formatted current recording time updates.
    var formattedCurrentTimeSubject: PassthroughSubject<String, Never> { get }
    
    /// Stream providing formatted playback duration updates.
    var playingDurationSubject: PassthroughSubject<String, Never> { get }
    
    /// Stream providing the current state of the recording button.
    var recordingButtonState: CurrentValueSubject<RecordingState, Never> { get }
    
    /// Stream providing the current state of the playback button.
    var playButtonState: CurrentValueSubject<PlayingState, Never> { get }
}

/// Protocol combining input and output interfaces for the audio recording and playback view model.
protocol AudioRecorderViewModelType {
    /// Input actions for controlling audio recording and playback.
    var inputs: AudioRecorderViewModelInputs { get }
    
    /// Output data streams and state updates for audio recording and playback.
    var outputs: AudioRecorderViewModelOutputs { get }
}

/// View model managing audio recording and playback operations.
final class AudioRecorderViewModel: AudioRecorderViewModelInputs, AudioRecorderViewModelOutputs, AudioRecorderViewModelType {
    
    // MARK: - Properties
    
    /// Combined input actions for controlling audio recording and playback.
    var inputs: AudioRecorderViewModelInputs { return self }
    
    /// Combined output data streams and state updates for audio recording and playback.
    var outputs: AudioRecorderViewModelOutputs { return self }
    
    private let audioRecorder: AudioRecording
    private let audioPlayer: AudioPlaying
    private var cancellables = Set<AnyCancellable>()
    
    private(set) var isRecordingSubject: CurrentValueSubject<Bool, Never> = .init(false)
    private(set) var isPlayingSubject: CurrentValueSubject<Bool, Never> = .init(false)
    private(set) var formattedCurrentTimeSubject: PassthroughSubject<String, Never> = .init()
    private(set) var recordingButtonState: CurrentValueSubject<RecordingState, Never> = .init(.start)
    private(set) var playButtonState: CurrentValueSubject<PlayingState, Never> = .init(.none)
    private(set) var playingDurationSubject: PassthroughSubject<String, Never> = .init()
    
    private var isRecording: Bool = false {
        didSet {
            self.isRecordingSubject.send(self.isRecording)
        }
    }
    
    /// Initializes the view model with audio recording and playback components.
    ///
    /// - Parameters:
    ///   - audioRecorder: Instance conforming to `AudioRecording` for managing recording operations.
    ///   - audioPlayer: Instance conformin
    init(audioRecorder: AudioRecording, audioPlayer: AudioPlaying) {
        self.audioRecorder = audioRecorder
        self.audioPlayer = audioPlayer
        self.audioPlayer.delegate = self
        self.audioRecorder.delegate = self
    }
    
    func bindViewModel() {
        // Subscribe to timer updates
        
        self.recordingButtonState.send(.start)
        self.playButtonState.send(.none)
    }
    
    // MARK: - Recording Control
    
    func startRecording() {
        if self.recordingButtonState.value == .start {
            self.audioRecorder.startRecording()
            isRecording = true
            self.recordingButtonState.send(.paused)
        } else if self.recordingButtonState.value == .paused {
            self.pauseRecording()
            isRecording = false
            self.recordingButtonState.send(.resume)
        } else if self.recordingButtonState.value == .resume {
            self.resumeRecording()
            isRecording = true
            self.recordingButtonState.send(.paused)
        }
    }
    
    func stopRecording() {
        audioRecorder.stopRecording()
        isRecording = false
        recordingButtonState.send(.start)
    }
    
    func pauseRecording() {
        audioRecorder.pauseRecording()
        isRecording = false
    }
    
    func resumeRecording() {
        audioRecorder.resumeRecording()
        isRecording = true
    }
    
    // MARK: - Playing Control
    
    func playRecording() {
        guard playButtonState.value != .stop else {
            stopPlaying()
            return
        }
        
        guard let url = audioRecorder._recordingURL else {
            print("Failed to play due to invalid URL")
            return
        }
        
        audioPlayer.playRecording(url: url)
        isPlayingSubject.send(true)
        playButtonState.send(.stop)
    }
    
    func stopPlaying() {
        audioPlayer.stopPlaying()
        isPlayingSubject.send(false)
        playButtonState.send(.play)
    }
}

// MARK: - AudioRecorderDelegate

extension AudioRecorderViewModel: AudioRecordingDelegate {
    func didFinishRecording(success: Bool) {
        print("Audio recording completed successfully - \(success)")
    }
    
    func recordingDuration(duration: String) {
        self.formattedCurrentTimeSubject.send(duration)
    }
}

// MARK: - AudioPlayerDelegate

extension AudioRecorderViewModel: AudioPlayerDelegate {
    func didFinishPlaying(success: Bool) {
        isPlayingSubject.send(false)
        playButtonState.send(.play)
    }
    
    func updatePlaybackTime(currentTime: TimeInterval, duration: TimeInterval) {
        print("Playing timer - currentTime \(currentTime), out of duration - \(duration)")
        self.playingDurationSubject.send("\(currentTime.formattedTime)")
    }
}

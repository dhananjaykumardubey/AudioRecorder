//
//  AudioRecordingMock.swift
//  AudioRecorderTests
//
//  Created by Apple on 22/06/24.
//

import Foundation
@testable import AudioRecorder

// Mock classes for AudioRecording and AudioPlaying protocols
class AudioRecordingMock: AudioRecording {
    
    weak var delegate: AudioRecordingDelegate?
    var _recordingURL: URL?
    
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var pauseRecordingCalled = false
    var resumeRecordingCalled = false
    var didFinishRecordingCalled = false
    
    func startRecording() {
        startRecordingCalled = true
    }
    
    func stopRecording() {
        stopRecordingCalled = true
    }
    
    func pauseRecording() {
        pauseRecordingCalled = true
    }
    
    func resumeRecording() {
        resumeRecordingCalled = true
    }
}

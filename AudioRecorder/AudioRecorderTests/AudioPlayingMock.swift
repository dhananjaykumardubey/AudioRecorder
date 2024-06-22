//
//  AudioPlayingMock.swift
//  AudioRecorderTests
//
//  Created by Apple on 22/06/24.
//

import Foundation
@testable import AudioRecorder

class AudioPlayingMock: AudioPlaying {
    
    weak var delegate: AudioPlayerDelegate?
    
    var playRecordingCalled = false
    var stopPlayingCalled = false
    var pausePlayingCalled = false
    var resumePlayingCalled = false
    var updatePlaybackTimeCalled = false

    var playRecordingURL: URL?
    
    func playRecording(url: URL) {
        playRecordingCalled = true
        playRecordingURL = url
    }
    
    func stopPlaying() {
        stopPlayingCalled = true
    }
    
    func pausePlaying() {
        pausePlayingCalled = true
    }
    
    func resumePlaying() {
        resumePlayingCalled = true
    }
}

//
//  AudioRecorderTests.swift
//  AudioRecorderTests
//
//  Created by Apple on 22/06/24.
//

import XCTest
import Combine
@testable import AudioRecorder

class AudioRecorderViewModelTests: XCTestCase {

    var viewModel: AudioRecorderViewModel!
    var audioRecorderMock: AudioRecordingMock!
    var audioPlayerMock: AudioPlayingMock!
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        
        // Initialize mocks
        audioRecorderMock = AudioRecordingMock()
        audioPlayerMock = AudioPlayingMock()
        
        // Initialize view model with mocks
        viewModel = AudioRecorderViewModel(audioRecorder: audioRecorderMock, audioPlayer: audioPlayerMock)
        audioRecorderMock.delegate = viewModel
        audioPlayerMock.delegate = viewModel
    }
    
    override func tearDown() {
        viewModel = nil
        audioRecorderMock = nil
        audioPlayerMock = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testStartRecording() {
        viewModel.inputs.startRecording()
        
        XCTAssertTrue(audioRecorderMock.startRecordingCalled)
        XCTAssertTrue(viewModel.outputs.isRecordingSubject.value)
        XCTAssertEqual(viewModel.outputs.recordingButtonState.value, .paused)
    }
    
    func testStopRecording() {
        viewModel.inputs.startRecording() // Start recording first
        viewModel.inputs.stopRecording()
        
        XCTAssertTrue(audioRecorderMock.stopRecordingCalled)
        XCTAssertFalse(viewModel.outputs.isRecordingSubject.value)
        XCTAssertEqual(viewModel.outputs.recordingButtonState.value, .start)
    }
    
    func testPauseRecording() {
        viewModel.inputs.startRecording() // Start recording first
        viewModel.inputs.pauseRecording()
        
        XCTAssertTrue(audioRecorderMock.pauseRecordingCalled)
        XCTAssertFalse(viewModel.outputs.isRecordingSubject.value)
        XCTAssertEqual(viewModel.outputs.recordingButtonState.value, .paused)
    }
    
    func testResumeRecording() {
        viewModel.inputs.startRecording() // Start recording first
        viewModel.inputs.pauseRecording() // Then pause
        viewModel.inputs.resumeRecording()
        
        XCTAssertTrue(audioRecorderMock.resumeRecordingCalled)
        XCTAssertTrue(viewModel.outputs.isRecordingSubject.value)
        XCTAssertEqual(viewModel.outputs.recordingButtonState.value, .paused)
    }
    
    func testPlayRecording() {
        // Set a mock recording URL to simulate a recorded file
        audioRecorderMock._recordingURL = URL(string: "file://mockRecording.aac")
        
        viewModel.inputs.playRecording()
        
        XCTAssertTrue(audioPlayerMock.playRecordingCalled)
        XCTAssertEqual(audioPlayerMock.playRecordingURL, audioRecorderMock._recordingURL)
        XCTAssertTrue(viewModel.outputs.isPlayingSubject.value)
        XCTAssertEqual(viewModel.outputs.playButtonState.value, .stop)
    }
    
    func testStopPlaying() {
        viewModel.inputs.playRecording() // Start playing first
        viewModel.inputs.stopPlaying()
        
        XCTAssertTrue(audioPlayerMock.stopPlayingCalled)
        XCTAssertFalse(viewModel.outputs.isPlayingSubject.value)
        XCTAssertEqual(viewModel.outputs.playButtonState.value, .play)
    }
    
    func testRecordingDurationDelegate() {
        let expectation = self.expectation(description: "Recording duration updated")
        var receivedDuration: String?
        
        viewModel.outputs.formattedCurrentTimeSubject
            .sink { duration in
                receivedDuration = duration
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate delegate call
        viewModel.recordingDuration(duration: "00:30")
        
        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertEqual(receivedDuration, "00:30")
    }
    
    func testPlaybackTimeDelegate() {
        let expectation = self.expectation(description: "Playback time updated")
        var receivedDuration: String?
        
        viewModel.outputs.playingDurationSubject
            .sink { duration in
                receivedDuration = duration
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate delegate call
        viewModel.updatePlaybackTime(currentTime: 30.0, duration: 45.0)
        
        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertEqual(receivedDuration, "00:00:30")
    }
}

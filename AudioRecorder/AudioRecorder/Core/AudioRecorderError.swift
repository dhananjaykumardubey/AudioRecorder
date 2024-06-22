//
//  AudioRecorderError.swift
//  AudioRecorder
//
//  Created by Apple on 22/06/24.
//

import Foundation

enum AudioRecorderError: Error {
    case fileInitialization(String)
    case audioSessionSetup(String)
    case audioFormatSetup(String)
}

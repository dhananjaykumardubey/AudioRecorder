//
//  TimeInterval+Utilities.swift
//  AudioRecorder
//
//  Created by Apple on 22/06/24.
//

import Foundation

extension TimeInterval {
    var formattedTime: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

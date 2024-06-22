//
//  AudioFileManager.swift
//  AudioRecorder
//
//  Created by Apple on 22/06/24.
//

import Foundation

protocol FileManagement {
    func createNewAudioFile() -> URL?
    func saveRecording(from sourceURL: URL, with fileName: String) throws
    func deleteRecording(at url: URL) throws
}

class AudioFileManager: FileManagement {
    static let shared = AudioFileManager()
    
    private let fileManagerQueue = DispatchQueue(label: "com.audioFileManager.queue", attributes: .concurrent)
    private let folderName = "Recordings"

    private init() {}
    
    private func createDirectoryIfNeeded() throws {
        fileManagerQueue.async(flags: .barrier) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let recordingsPath = documentsPath.appendingPathComponent(self.folderName)
            if !FileManager.default.fileExists(atPath: recordingsPath.path) {
                do {
                    try FileManager.default.createDirectory(at: recordingsPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Failed to create directory: \(error.localizedDescription)")
                }
            }
        }
    }

    func createNewAudioFile() -> URL? {
        var fileURL: URL?
        fileManagerQueue.sync {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let recordingsPath = documentsPath.appendingPathComponent(self.folderName)
            
            // Ensure the directory exists
            if !FileManager.default.fileExists(atPath: recordingsPath.path) {
                do {
                    try self.createDirectoryIfNeeded()
                } catch {
                    print("Failed to create directory: \(error.localizedDescription)")
                }
            }

            let uniqueFileName = UUID().uuidString + ".m4a"
            fileURL = recordingsPath.appendingPathComponent(uniqueFileName)
        }
        return fileURL
    }

    func saveRecording(from sourceURL: URL, with fileName: String) throws {
        try fileManagerQueue.sync {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let recordingsPath = documentsPath.appendingPathComponent(self.folderName)
            let newFilePath = recordingsPath.appendingPathComponent(fileName + ".caf")
            try FileManager.default.moveItem(at: sourceURL, to: newFilePath)
        }
    }
    
    func deleteRecording(at url: URL) throws {
        try fileManagerQueue.sync {
            try FileManager.default.removeItem(at: url)
        }
    }
}

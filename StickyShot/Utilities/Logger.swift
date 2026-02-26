/**
 * Logger.swift
 * ~~~~~~~~~~~~~
 *
 * Centralized logging utility that writes to ~/.config/stickyshot/debug.log
 */

import Foundation


class Logger {

    static let shared = Logger()

    private let logFile: URL
    private let dateFormatter: DateFormatter


    private init() {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/stickyshot")
        logFile = configDir.appendingPathComponent("debug.log")

        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
    }


    func log(_ message: String, category: String = "App") {
        guard ConfigManager.shared.config.debugLogging else { return }

        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(category)] \(message)\n"

        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile.path) {
                if let handle = try? FileHandle(forWritingTo: logFile) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: logFile)
            }
        }

        // Also print to console
        print(logMessage, terminator: "")
    }


    func clearLog() {
        try? FileManager.default.removeItem(at: logFile)
    }
}


// Convenience function
func debugLog(_ message: String, category: String = "App") {
    Logger.shared.log(message, category: category)
}

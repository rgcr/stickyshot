/**
 * ConfigManager.swift
 * ~~~~~~~~~~~~~~~~~~~~
 *
 * Manages loading and saving application configuration to JSON file
 */

import Foundation


class ConfigManager {

    static let shared = ConfigManager()

    private let configDirectory: URL
    private let configFile: URL

    private(set) var config: AppConfig


    private init() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        configDirectory = homeDirectory.appendingPathComponent(".config/stickyshot")
        configFile = configDirectory.appendingPathComponent("config.json")
        config = AppConfig.defaultConfig

        loadConfig()
    }


    // MARK: - Public Methods

    func save(_ config: AppConfig) {
        self.config = config
        saveConfig()
    }


    func updateShortcut(key: String, modifiers: [String]) {
        config.shortcut.key = key
        config.shortcut.modifiers = modifiers
        saveConfig()
    }


    func updateBorder(show: Bool, color: String, width: Int) {
        config.showBorder = show
        config.borderColor = color
        config.borderWidth = width
        saveConfig()
    }


    func updateMaxPreviews(_ count: Int) {
        config.maxPreviews = count
        saveConfig()
    }


    func updateSaveDirectory(_ path: String) {
        config.saveDirectory = path
        saveConfig()
    }


    func updateExportFormat(_ format: String) {
        config.exportFormat = format
        saveConfig()
    }


    func updateDrawColor(_ color: String) {
        config.drawColor = color
        saveConfig()
    }


    func updateDebugLogging(_ enabled: Bool) {
        config.debugLogging = enabled
        saveConfig()
    }


    func updateLaunchAtLogin(_ enabled: Bool) {
        config.launchAtLogin = enabled
        saveConfig()
    }


    // MARK: - Private Methods

    private func loadConfig() {
        if !FileManager.default.fileExists(atPath: configFile.path) {
            createDefaultConfig()
            return
        }

        do {
            let data = try Data(contentsOf: configFile)
            let decoder = JSONDecoder()
            config = try decoder.decode(AppConfig.self, from: data)
        } catch {
            debugLog("Failed to load config: \(error)", category: "ConfigManager")
            config = AppConfig.defaultConfig
        }
    }


    private func saveConfig() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configFile)
        } catch {
            debugLog("Failed to save config: \(error)", category: "ConfigManager")
        }
    }


    private func createDefaultConfig() {
        do {
            try FileManager.default.createDirectory(
                at: configDirectory,
                withIntermediateDirectories: true
            )
            saveConfig()
        } catch {
            debugLog("Failed to create config directory: \(error)", category: "ConfigManager")
        }
    }
}

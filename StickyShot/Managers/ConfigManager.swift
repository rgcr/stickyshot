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


    func updateBlueBorder(_ show: Bool) {
        config.showBlueBorder = show
        saveConfig()
    }


    func updateSaveDirectory(_ path: String) {
        config.saveDirectory = path
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
            print("Failed to load config: \(error)")
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
            print("Failed to save config: \(error)")
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
            print("Failed to create config directory: \(error)")
        }
    }
}

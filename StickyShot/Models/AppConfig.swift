/**
 * AppConfig.swift
 * ~~~~~~~~~~~~~~~~
 *
 * Configuration model for StickyShot application settings
 */

import Foundation


struct ShortcutConfig: Codable {
    var key: String
    var modifiers: [String]


    static var defaultConfig: ShortcutConfig {
        return ShortcutConfig(key: "2", modifiers: ["command", "shift"])
    }
}


struct AppConfig: Codable {
    var shortcut: ShortcutConfig
    var showBlueBorder: Bool
    var saveDirectory: String
    var debugLogging: Bool
    var launchAtLogin: Bool


    static var defaultConfig: AppConfig {
        let desktop = NSHomeDirectory() + "/Desktop"
        return AppConfig(
            shortcut: ShortcutConfig.defaultConfig,
            showBlueBorder: true,
            saveDirectory: desktop,
            debugLogging: false,
            launchAtLogin: false
        )
    }
}

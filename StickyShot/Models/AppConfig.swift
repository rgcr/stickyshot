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
    var showBorder: Bool
    var borderColor: String
    var borderWidth: Int
    var maxPreviews: Int
    var saveDirectory: String
    var exportFormat: String
    var drawColor: String
    var debugLogging: Bool
    var launchAtLogin: Bool

    // Support old config key
    enum CodingKeys: String, CodingKey {
        case shortcut
        case showBorder
        case showBlueBorder  // Legacy key
        case borderColor
        case borderWidth
        case maxPreviews
        case saveDirectory
        case exportFormat
        case drawColor
        case debugLogging
        case launchAtLogin
    }

    init(shortcut: ShortcutConfig, showBorder: Bool, borderColor: String, borderWidth: Int, maxPreviews: Int, saveDirectory: String, exportFormat: String, drawColor: String, debugLogging: Bool, launchAtLogin: Bool) {
        self.shortcut = shortcut
        self.showBorder = showBorder
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.maxPreviews = maxPreviews
        self.saveDirectory = saveDirectory
        self.exportFormat = exportFormat
        self.drawColor = drawColor
        self.debugLogging = debugLogging
        self.launchAtLogin = launchAtLogin
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        shortcut = try container.decode(ShortcutConfig.self, forKey: .shortcut)
        
        // Try new key first, fall back to legacy key
        if let show = try? container.decode(Bool.self, forKey: .showBorder) {
            showBorder = show
        } else {
            showBorder = try container.decodeIfPresent(Bool.self, forKey: .showBlueBorder) ?? true
        }
        
        borderColor = try container.decodeIfPresent(String.self, forKey: .borderColor) ?? "#4466FF"
        borderWidth = try container.decodeIfPresent(Int.self, forKey: .borderWidth) ?? 1
        maxPreviews = try container.decodeIfPresent(Int.self, forKey: .maxPreviews) ?? 10
        saveDirectory = try container.decode(String.self, forKey: .saveDirectory)
        exportFormat = try container.decodeIfPresent(String.self, forKey: .exportFormat) ?? "png"
        drawColor = try container.decodeIfPresent(String.self, forKey: .drawColor) ?? "#FF0000"
        debugLogging = try container.decodeIfPresent(Bool.self, forKey: .debugLogging) ?? false
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(shortcut, forKey: .shortcut)
        try container.encode(showBorder, forKey: .showBorder)
        try container.encode(borderColor, forKey: .borderColor)
        try container.encode(borderWidth, forKey: .borderWidth)
        try container.encode(maxPreviews, forKey: .maxPreviews)
        try container.encode(saveDirectory, forKey: .saveDirectory)
        try container.encode(exportFormat, forKey: .exportFormat)
        try container.encode(drawColor, forKey: .drawColor)
        try container.encode(debugLogging, forKey: .debugLogging)
        try container.encode(launchAtLogin, forKey: .launchAtLogin)
    }

    static var defaultConfig: AppConfig {
        let desktop = NSHomeDirectory() + "/Desktop"
        return AppConfig(
            shortcut: ShortcutConfig.defaultConfig,
            showBorder: true,
            borderColor: "#4466FF",
            borderWidth: 1,
            maxPreviews: 10,
            saveDirectory: desktop,
            exportFormat: "png",
            drawColor: "#FF0000",
            debugLogging: false,
            launchAtLogin: false
        )
    }
}

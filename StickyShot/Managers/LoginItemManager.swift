/**
 * LoginItemManager.swift
 * ~~~~~~~~~~~~~~~~~~~~~~~
 *
 * Manages launch at login functionality using SMAppService (macOS 13+)
 */

import Foundation
import ServiceManagement


class LoginItemManager {

    static let shared = LoginItemManager()

    private init() {}


    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return ConfigManager.shared.config.launchAtLogin
        }
    }


    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    debugLog("Login item registered", category: "LoginItemManager")
                } else {
                    try SMAppService.mainApp.unregister()
                    debugLog("Login item unregistered", category: "LoginItemManager")
                }
            } catch {
                debugLog("Failed to update login item: \(error)", category: "LoginItemManager")
            }
        } else {
            debugLog("Launch at login requires macOS 13+", category: "LoginItemManager")
        }

        ConfigManager.shared.updateLaunchAtLogin(enabled)
    }
}

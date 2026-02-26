/**
 * PermissionsHelper.swift
 * ~~~~~~~~~~~~~~~~~~~~~~~~
 *
 * Handles checking and requesting macOS permissions for accessibility and screen recording
 */

import AppKit
import CoreGraphics


class PermissionsHelper {

    private static var hasPromptedForAccessibility = false
    private static var hasPromptedForScreenRecording = false


    // MARK: - Public Methods

    static func checkAndRequestPermissions() {
        // Only prompt once per app launch
        if !hasAccessibilityPermission() && !hasPromptedForAccessibility {
            hasPromptedForAccessibility = true
            requestAccessibilityPermission()
        }

        if !hasScreenRecordingPermission() && !hasPromptedForScreenRecording {
            hasPromptedForScreenRecording = true
            requestScreenRecordingPermission()
        }
    }


    static func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }


    static func hasScreenRecordingPermission() -> Bool {
        // Attempt a minimal screen capture to check permission
        let screenBounds = CGRect(x: 0, y: 0, width: 1, height: 1)

        guard let image = CGWindowListCreateImage(
            screenBounds,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            return false
        }

        return image.width > 0
    }


    // MARK: - Private Methods

    private static func requestAccessibilityPermission() {
        // This will show the system prompt
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }


    private static func requestScreenRecordingPermission() {
        // Screen recording permission is requested automatically when we try to capture
        // Just show a helpful alert
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Screen Recording Permission Required"
            alert.informativeText = "StickyShot needs screen recording permission to capture screenshots.\n\nPlease grant access in System Settings > Privacy & Security > Screen Recording."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

/**
 * HotkeyManager.swift
 * ~~~~~~~~~~~~~~~~~~~~
 *
 * Manages global hotkey registration using NSEvent global monitor
 */

import AppKit
import Carbon


class HotkeyManager {

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var registeredKey: UInt16 = 0
    private var registeredModifiers: NSEvent.ModifierFlags = []
    private var callback: (() -> Void)?
    var isPaused: Bool = false


    deinit {
        unregister()
    }


    // MARK: - Public Methods

    func register(key: String, modifiers: [String], callback: @escaping () -> Void) {
        unregister()

        self.callback = callback

        guard let keyCode = KeyCodeMapping.keyCode(for: key) else {
            debugLog("Unknown key: \(key)", category: "HotkeyManager")
            return
        }

        registeredKey = UInt16(keyCode)
        registeredModifiers = KeyCodeMapping.modifierFlagsNS(from: modifiers)

        debugLog("Registering hotkey: key=\(key) (code=\(registeredKey)), modifiers=\(registeredModifiers)", category: "HotkeyManager")

        // Global monitor for when app is not focused
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, !self.isPaused else { return }
            debugLog("Key event: keyCode=\(event.keyCode), expected=\(self.registeredKey)", category: "HotkeyManager")
            if event.keyCode == self.registeredKey {
                debugLog("Hotkey matched, calling handleKeyEvent", category: "HotkeyManager")
                self.handleKeyEvent(event)
            }
        }

        if globalMonitor != nil {
            debugLog("Global monitor registered successfully", category: "HotkeyManager")
        } else {
            debugLog("ERROR: Global monitor is nil - check Accessibility permissions", category: "HotkeyManager")
        }

        // Local monitor disabled for now
        localMonitor = nil
    }


    func unregister() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }

        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }

        callback = nil
    }


    // MARK: - Private Methods

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        if isPaused {
            debugLog("Hotkey paused, ignoring", category: "HotkeyManager")
            return false
        }

        let pressedModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        debugLog("Checking modifiers: pressed=\(pressedModifiers.rawValue), expected=\(registeredModifiers.rawValue)", category: "HotkeyManager")

        if event.keyCode == registeredKey && pressedModifiers == registeredModifiers {
            debugLog("Hotkey triggered! Calling callback...", category: "HotkeyManager")
            callback?()
            return true
        }

        return false
    }
}

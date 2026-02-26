/**
 * AppDelegate.swift
 * ~~~~~~~~~~~~~~~~~~
 *
 * Application delegate handling menu bar setup, lifecycle, and coordination
 */

import AppKit
import SwiftUI


class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var hotkeyManager: HotkeyManager?
    private var stickyWindowManager: StickyWindowManager?
    private var screenCaptureManager: ScreenCaptureManager?
    private var preferencesWindow: NSWindow?


    func applicationDidFinishLaunching(_ notification: Notification) {
        debugLog("App starting...", category: "AppDelegate")

        setupMenuBar()
        debugLog("Menu bar setup done", category: "AppDelegate")

        setupManagers()
        debugLog("Managers setup done", category: "AppDelegate")

        registerHotkey()
        debugLog("Hotkey registered", category: "AppDelegate")

        // Run as menu bar only app (no dock icon)
        NSApp.setActivationPolicy(.accessory)

        debugLog("App launched successfully", category: "AppDelegate")
    }


    // MARK: - Setup

    private func setupManagers() {
        stickyWindowManager = StickyWindowManager()
        hotkeyManager = HotkeyManager()
        screenCaptureManager = ScreenCaptureManager { [weak self] image, frame in
            self?.handleScreenCapture(image: image, frame: frame)
        }
    }


    private func setupMenuBar() {
        guard statusItem == nil else {
            debugLog("Status item already exists, skipping", category: "AppDelegate")
            return
        }
        
        debugLog("Creating status item...", category: "AppDelegate")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.behavior = .removalAllowed
        debugLog("Status item created: \(statusItem != nil)", category: "AppDelegate")

        if let button = statusItem?.button {
            let image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "StickyShot")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeft
            debugLog("Menu bar icon set", category: "AppDelegate")
        } else {
            debugLog("ERROR: Could not get status item button", category: "AppDelegate")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Take Screenshot", action: #selector(takeScreenshot), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Close All Previews", action: #selector(closeAllPreviews), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
        debugLog("Menu assigned to status item", category: "AppDelegate")
    }


    private func registerHotkey() {
        let config = ConfigManager.shared.config

        hotkeyManager?.register(
            key: config.shortcut.key,
            modifiers: config.shortcut.modifiers
        ) { [weak self] in
            self?.takeScreenshot()
        }
    }


    private func checkPermissions() {
        PermissionsHelper.checkAndRequestPermissions()
    }


    // MARK: - Actions

    @objc private func takeScreenshot() {
        hotkeyManager?.isPaused = true
        screenCaptureManager?.startSelection()
    }


    @objc private func closeAllPreviews() {
        stickyWindowManager?.closeAll()
    }


    @objc private func showPreferences() {
        if preferencesWindow == nil {
            let preferencesView = PreferencesView(
                onSave: { [weak self] in
                    self?.hotkeyManager?.unregister()
                    self?.registerHotkey()
                    self?.preferencesWindow?.close()
                }
            )

            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 600),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            preferencesWindow?.title = "Preferences"
            preferencesWindow?.contentView = NSHostingView(rootView: preferencesView)
            preferencesWindow?.center()
            preferencesWindow?.isReleasedWhenClosed = false
        }

        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }


    @objc private func quitApp() {
        NSApp.terminate(nil)
    }


    // MARK: - Screenshot Handling

    private func handleScreenCapture(image: NSImage, frame: NSRect) {
        debugLog("handleScreenCapture called", category: "AppDelegate")
        stickyWindowManager?.addPreview(image: image, frame: frame)
        debugLog("Preview added", category: "AppDelegate")

        // Re-enable hotkey after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.hotkeyManager?.isPaused = false
            debugLog("Hotkey re-enabled", category: "AppDelegate")
        }
    }


    func reloadHotkey() {
        hotkeyManager?.unregister()
        registerHotkey()
    }
}

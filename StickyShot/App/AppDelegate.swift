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
        screenCaptureManager = ScreenCaptureManager(
            onCapture: { [weak self] image, frame in
                self?.handleScreenCapture(image: image, frame: frame)
            },
            onCancel: { [weak self] in
                self?.hotkeyManager?.isPaused = false
                debugLog("Selection cancelled, hotkey re-enabled", category: "AppDelegate")
            }
        )
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
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "Take Screenshot", action: #selector(takeScreenshot), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let closeAllItem = NSMenuItem(title: "Close All Previews", action: #selector(closeAllPreviews), keyEquivalent: "")
        closeAllItem.tag = 100  // Tag to find this item
        menu.addItem(closeAllItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Help", action: #selector(showHelp), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "About StickyShot", action: #selector(showAbout), keyEquivalent: ""))
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
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 665),
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


    @objc private func showHelp() {
        let config = ConfigManager.shared.config
        let shortcut = formatShortcut(key: config.shortcut.key, modifiers: config.shortcut.modifiers)

        let alert = NSAlert()
        alert.messageText = "StickyShot Help"

        let padding = String(repeating: " ", count: max(0, 5 - shortcut.count))
        let text = """
        Keyboard Shortcuts:

        \(shortcut)\(padding) - Take screenshot
        ⌘C      - Copy to clipboard
        ⌘S      - Save to file
        ⌘Z      - Undo drawing
        Esc     - Close preview


        Tips:

        • Drag to move previews
        • Right-click to draw annotations
        • Scroll to adjust opacity in each preview
          - When copying/saving, the original full opacity image is used

        Settings in Preferences.
        """

        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.count)

        attributedString.addAttribute(.font, value: NSFont.systemFont(ofSize: 14), range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 450, height: 300))
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textStorage?.setAttributedString(attributedString)

        alert.accessoryView = textView
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }


    private func formatShortcut(key: String, modifiers: [String]) -> String {
        var result = ""
        if modifiers.contains("control") { result += "⌃" }
        if modifiers.contains("option") { result += "⌥" }
        if modifiers.contains("shift") { result += "⇧" }
        if modifiers.contains("command") { result += "⌘" }
        result += key.uppercased()
        return result
    }


    @objc private func showAbout() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        let text = """
        Version \(version)

        Screenshots that stay on top.
        Capture any screen region as a floating preview window.

        © 2026 Roger C.

        """

        let urlString = "https://github.com/rgcr/stickyshot"
        let fullText = text + urlString

        let attributedString = NSMutableAttributedString(string: fullText)
        let fullRange = NSRange(location: 0, length: fullText.count)
        let urlRange = (fullText as NSString).range(of: urlString)

        attributedString.addAttribute(.font, value: NSFont.systemFont(ofSize: 14), range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
        attributedString.addAttribute(.link, value: urlString, range: urlRange)

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 360, height: 160))
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textStorage?.setAttributedString(attributedString)

        let alert = NSAlert()
        alert.messageText = "StickyShot"
        alert.accessoryView = textView
        alert.alertStyle = .informational

        if let icon = NSImage(named: NSImage.applicationIconName) {
            alert.icon = icon
        }

        alert.addButton(withTitle: "OK")
        alert.runModal()
    }


    @objc private func checkForUpdates() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let repoURL = "https://api.github.com/repos/rgcr/stickyshot/releases/latest"

        guard let url = URL(string: repoURL) else { return }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 10
        let session = URLSession(configuration: config)

        let task = session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorTimedOut || nsError.code == NSURLErrorNotConnectedToInternet {
                        self.showUpdateError("Unable to check for updates. Please check your internet connection.")
                    } else {
                        self.showUpdateError("Could not check for updates: \(error.localizedDescription)")
                    }
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    self.showUpdateError("Could not parse update information.")
                    return
                }

                let latestVersion = tagName.replacingOccurrences(of: "v", with: "")

                if self.isNewerVersion(latestVersion, than: currentVersion) {
                    self.showUpdateAvailable(latestVersion: latestVersion, currentVersion: currentVersion)
                } else {
                    self.showUpToDate(currentVersion: currentVersion)
                }
            }
        }
        task.resume()
    }


    private func isNewerVersion(_ latest: String, than current: String) -> Bool {
        let latestParts = latest.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(latestParts.count, currentParts.count) {
            let l = i < latestParts.count ? latestParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }


    private func showUpdateAvailable(latestVersion: String, currentVersion: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = """
        A new version of StickyShot is available!

        Current version: \(currentVersion)
        Latest version: \(latestVersion)

        To update:
        brew upgrade --cask stickyshot

        Or download from GitHub releases.

        Note: You will need to re-grant permissions in
        System Settings → Privacy & Security
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open GitHub")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "https://github.com/rgcr/stickyshot/releases/latest") {
                NSWorkspace.shared.open(url)
            }
        }
    }


    private func showUpToDate(currentVersion: String) {
        let alert = NSAlert()
        alert.messageText = "You're up to date!"
        alert.informativeText = "StickyShot \(currentVersion) is the latest version."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }


    private func showUpdateError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
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


// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        if let closeAllItem = menu.item(withTag: 100) {
            let count = stickyWindowManager?.previewCount ?? 0
            if count > 0 {
                closeAllItem.title = "Close All Previews (\(count))"
                closeAllItem.isEnabled = true
            } else {
                closeAllItem.title = "Close All Previews"
                closeAllItem.isEnabled = false
            }
        }
    }
}

/**
 * PreferencesView.swift
 * ~~~~~~~~~~~~~~~~~~~~~~
 *
 * Preferences window with shortcut recorder using Carbon hotkeys
 */

import SwiftUI
import Carbon


struct PreferencesView: View {

    @State private var selectedKey: String
    @State private var selectedModifiers: NSEvent.ModifierFlags
    @State private var showBorder: Bool
    @State private var borderColor: Color
    @State private var borderWidth: Int
    @State private var maxPreviews: Int
    @State private var saveDirectory: String
    @State private var exportFormat: String
    @State private var drawColor: Color
    @State private var debugLogging: Bool
    @State private var launchAtLogin: Bool
    @State private var isRecording: Bool = false

    private let exportFormats = ["png", "jpeg"]
    private let borderWidths = [1, 2, 3, 4, 5]
    private let maxPreviewOptions = [5, 10, 15, 20]

    var onSave: (() -> Void)?


    init(onSave: (() -> Void)? = nil) {
        let config = ConfigManager.shared.config
        let mods = config.shortcut.modifiers

        _selectedKey = State(initialValue: config.shortcut.key.uppercased())

        var flags: NSEvent.ModifierFlags = []
        if mods.contains("command") { flags.insert(.command) }
        if mods.contains("shift") { flags.insert(.shift) }
        if mods.contains("option") { flags.insert(.option) }
        if mods.contains("control") { flags.insert(.control) }
        _selectedModifiers = State(initialValue: flags)

        _showBorder = State(initialValue: config.showBorder)
        _borderColor = State(initialValue: Color(hex: config.borderColor))
        _borderWidth = State(initialValue: config.borderWidth)
        _maxPreviews = State(initialValue: config.maxPreviews)
        _saveDirectory = State(initialValue: config.saveDirectory)
        _exportFormat = State(initialValue: config.exportFormat)
        _drawColor = State(initialValue: Color(hex: config.drawColor))
        _debugLogging = State(initialValue: config.debugLogging)
        _launchAtLogin = State(initialValue: LoginItemManager.shared.isEnabled)

        self.onSave = onSave
    }


    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 8) {
                    shortcutSection
                    saveLocationSection
                    appearanceSection
                    advancedSection
                }
                .padding(24)
            }

            Spacer()

            Divider()

            // Footer
            footerView
        }
        .frame(width: 380, height: 665)
        .background(Color(NSColor.windowBackgroundColor))
    }


    private var headerView: some View {
        VStack(spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)

                Text("StickyShot")
                    .font(.system(size: 18, weight: .semibold))
            }

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(NSColor.controlBackgroundColor))
    }


    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Screenshot Shortcut")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // Shortcut recorder
                    ShortcutRecorder(
                        keyCode: selectedKey,
                        modifiers: selectedModifiers,
                        isRecording: $isRecording,
                        onShortcutCaptured: { key, mods in
                            selectedKey = key.uppercased()
                            selectedModifiers = mods
                        }
                    )

                    // Reset button
                    Button(action: resetShortcut) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("Reset to ⌘⇧2")
                }

                // Text representation
                Text(shortcutTextRepresentation)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }


    private var saveLocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Save")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("Location")
                        .foregroundColor(.secondary)

                    Text(saveDirectoryDisplay)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Choose...") {
                        chooseSaveDirectory()
                    }
                    .controlSize(.small)
                }

                HStack(spacing: 8) {
                    Text("Format")
                        .foregroundColor(.secondary)

                    Picker("", selection: $exportFormat) {
                        ForEach(exportFormats, id: \.self) { format in
                            Text(format.uppercased()).tag(format)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 80)

                    Spacer()
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }


    private var saveDirectoryDisplay: String {
        let path = saveDirectory
        if path.hasPrefix(NSHomeDirectory()) {
            return "~" + path.dropFirst(NSHomeDirectory().count)
        }
        return path
    }


    private var shortcutTextRepresentation: String {
        var parts: [String] = []

        if selectedModifiers.contains(.control) { parts.append("Control") }
        if selectedModifiers.contains(.option) { parts.append("Option") }
        if selectedModifiers.contains(.shift) { parts.append("Shift") }
        if selectedModifiers.contains(.command) { parts.append("Command") }

        parts.append(selectedKey.uppercased())

        return parts.joined(separator: " + ")
    }


    private func chooseSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = "Select folder to save screenshots"

        if let url = URL(string: "file://" + saveDirectory) {
            panel.directoryURL = url
        }

        if panel.runModal() == .OK, let url = panel.url {
            saveDirectory = url.path
        }
    }


    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Toggle(isOn: $showBorder) {
                        Text("Show border on previews")
                    }
                    .toggleStyle(.switch)
                    .controlSize(.small)

                    Spacer()
                }

                if showBorder {
                    HStack {
                        Text("Border Color")
                            .foregroundColor(.secondary)

                        ColorPicker("", selection: $borderColor, supportsOpacity: false)
                            .labelsHidden()

                        Spacer()

                        Text("Border Width")
                            .foregroundColor(.secondary)

                        Picker("", selection: $borderWidth) {
                            ForEach(borderWidths, id: \.self) { w in
                                Text("\(w)px").tag(w)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 70)
                    }
                }

                HStack {
                    Text("Max previews")
                        .foregroundColor(.secondary)

                    Picker("", selection: $maxPreviews) {
                        ForEach(maxPreviewOptions, id: \.self) { n in
                            Text("\(n)").tag(n)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 70)

                    Spacer()
                }
                
                HStack {
                    Text("Draw color")
                        .foregroundColor(.secondary)
                    
                    ColorPicker("", selection: $drawColor, supportsOpacity: false)
                        .labelsHidden()
                    
                    Spacer()
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }


    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Toggle(isOn: $launchAtLogin) {
                        Text("Launch at login")
                    }
                    .toggleStyle(.switch)
                    .controlSize(.small)

                    Spacer()
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Toggle(isOn: $debugLogging) {
                            Text("Enable debug logging")
                        }
                        .toggleStyle(.switch)
                        .controlSize(.small)

                        Spacer()
                    }

                    Text("Logs to ~/.config/stickyshot/debug.log")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }


    private var footerView: some View {
        HStack {
            Button("Reset to Defaults") {
                resetToDefaults()
            }
            .controlSize(.large)

            Spacer()

            Button("Save") {
                save()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(16)
    }


    private func save() {
        var mods: [String] = []
        if selectedModifiers.contains(.command) { mods.append("command") }
        if selectedModifiers.contains(.shift) { mods.append("shift") }
        if selectedModifiers.contains(.option) { mods.append("option") }
        if selectedModifiers.contains(.control) { mods.append("control") }

        if mods.isEmpty { mods = ["command"] }

        ConfigManager.shared.updateShortcut(key: selectedKey.lowercased(), modifiers: mods)
        ConfigManager.shared.updateBorder(show: showBorder, color: NSColor(borderColor).hexString, width: borderWidth)
        ConfigManager.shared.updateMaxPreviews(maxPreviews)
        ConfigManager.shared.updateSaveDirectory(saveDirectory)
        ConfigManager.shared.updateExportFormat(exportFormat)
        ConfigManager.shared.updateDrawColor(NSColor(drawColor).hexString)
        ConfigManager.shared.updateDebugLogging(debugLogging)
        LoginItemManager.shared.setEnabled(launchAtLogin)

        onSave?()
    }


    private func resetToDefaults() {
        let alert = NSAlert()
        alert.messageText = "Reset to Defaults?"
        alert.informativeText = "This will reset all settings to their default values. You will still need to click Save to apply."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            let defaults = AppConfig.defaultConfig
            selectedKey = defaults.shortcut.key.uppercased()
            selectedModifiers = modifiersFromStrings(defaults.shortcut.modifiers)
            showBorder = defaults.showBorder
            borderColor = Color(hex: defaults.borderColor)
            borderWidth = defaults.borderWidth
            maxPreviews = defaults.maxPreviews
            saveDirectory = defaults.saveDirectory
            exportFormat = defaults.exportFormat
            drawColor = Color(hex: defaults.drawColor)
            debugLogging = defaults.debugLogging
            launchAtLogin = false
        }
    }


    private func modifiersFromStrings(_ mods: [String]) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if mods.contains("command") { flags.insert(.command) }
        if mods.contains("shift") { flags.insert(.shift) }
        if mods.contains("option") { flags.insert(.option) }
        if mods.contains("control") { flags.insert(.control) }
        return flags
    }


    private func resetShortcut() {
        selectedKey = "2"
        selectedModifiers = [.command, .shift]
    }
}


// MARK: - Shortcut Recorder

struct ShortcutRecorder: NSViewRepresentable {

    let keyCode: String
    let modifiers: NSEvent.ModifierFlags
    @Binding var isRecording: Bool
    let onShortcutCaptured: (String, NSEvent.ModifierFlags) -> Void


    func makeCoordinator() -> Coordinator {
        Coordinator(onShortcutCaptured: onShortcutCaptured, isRecording: $isRecording)
    }


    func makeNSView(context: Context) -> ShortcutRecorderView {
        let view = ShortcutRecorderView()
        view.coordinator = context.coordinator
        view.updateDisplay(key: keyCode, modifiers: modifiers)
        return view
    }


    func updateNSView(_ nsView: ShortcutRecorderView, context: Context) {
        nsView.updateDisplay(key: keyCode, modifiers: modifiers)
        nsView.isRecording = isRecording
    }


    static func dismantleNSView(_ nsView: ShortcutRecorderView, coordinator: Coordinator) {
        coordinator.cleanup()
        nsView.coordinator = nil
    }


    // MARK: - Coordinator with Carbon Hotkey

    class Coordinator {
        private var onShortcutCaptured: ((String, NSEvent.ModifierFlags) -> Void)?
        private var isRecording: Binding<Bool>
        private var eventHandler: EventHandlerRef?
        private var installedHotKeys: [(EventHotKeyRef, UInt32, UInt32)] = []
        private var hotKeyMap: [UInt32: (String, NSEvent.ModifierFlags)] = [:]


        init(onShortcutCaptured: @escaping (String, NSEvent.ModifierFlags) -> Void,
             isRecording: Binding<Bool>) {
            self.onShortcutCaptured = onShortcutCaptured
            self.isRecording = isRecording
        }


        func startRecording() {
            DispatchQueue.main.async { [weak self] in
                self?.isRecording.wrappedValue = true
            }
            installCarbonHandler()
        }


        func stopRecording() {
            removeCarbonHandler()
            DispatchQueue.main.async { [weak self] in
                self?.isRecording.wrappedValue = false
            }
        }


        func cleanup() {
            removeCarbonHandler()
            onShortcutCaptured = nil
        }


        private func installCarbonHandler() {
            // Remove any existing handler
            removeCarbonHandler()

            // Install event handler for hotkey events
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                          eventKind: UInt32(kEventHotKeyPressed))

            let handlerRef = UnsafeMutablePointer<Coordinator>.allocate(capacity: 1)
            handlerRef.initialize(to: self)

            InstallEventHandler(
                GetApplicationEventTarget(),
                { (_, event, userData) -> OSStatus in
                    guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                    let coordinator = userData.assumingMemoryBound(to: Coordinator.self).pointee

                    var hotKeyID = EventHotKeyID()
                    GetEventParameter(event,
                                     EventParamName(kEventParamDirectObject),
                                     EventParamType(typeEventHotKeyID),
                                     nil,
                                     MemoryLayout<EventHotKeyID>.size,
                                     nil,
                                     &hotKeyID)

                    coordinator.handleHotKey(id: hotKeyID.id)
                    return noErr
                },
                1,
                &eventType,
                handlerRef,
                &eventHandler
            )

            // Register hotkeys for ALL key combinations we want to capture
            // This includes system shortcuts like Cmd+Shift+3/4/5
            registerAllHotKeys()
        }


        private func registerAllHotKeys() {
            // Key codes for common keys - order matters for lookup!
            let keyCodes: [(String, UInt32)] = [
                ("0", 29), ("1", 18), ("2", 19), ("3", 20), ("4", 21),
                ("5", 23), ("6", 22), ("7", 26), ("8", 28), ("9", 25),
                ("a", 0), ("b", 11), ("c", 8), ("d", 2), ("e", 14),
                ("f", 3), ("g", 5), ("h", 4), ("i", 34), ("j", 38),
                ("k", 40), ("l", 37), ("m", 46), ("n", 45), ("o", 31),
                ("p", 35), ("q", 12), ("r", 15), ("s", 1), ("t", 17),
                ("u", 32), ("v", 9), ("w", 13), ("x", 7), ("y", 16), ("z", 6)
            ]

            // Modifier combinations to capture
            let modifierCombos: [(UInt32, NSEvent.ModifierFlags)] = [
                // Command-based
                (UInt32(cmdKey), .command),
                (UInt32(cmdKey | shiftKey), [.command, .shift]),
                (UInt32(cmdKey | optionKey), [.command, .option]),
                (UInt32(cmdKey | controlKey), [.command, .control]),
                (UInt32(cmdKey | shiftKey | optionKey), [.command, .shift, .option]),
                (UInt32(cmdKey | shiftKey | controlKey), [.command, .shift, .control]),
                (UInt32(cmdKey | optionKey | controlKey), [.command, .option, .control]),
                (UInt32(cmdKey | shiftKey | optionKey | controlKey), [.command, .shift, .option, .control]),
                // Option-based (without command)
                (UInt32(optionKey), .option),
                (UInt32(optionKey | shiftKey), [.option, .shift]),
                (UInt32(optionKey | controlKey), [.option, .control]),
                (UInt32(optionKey | shiftKey | controlKey), [.option, .shift, .control]),
                // Control-based
                (UInt32(controlKey), .control),
                (UInt32(controlKey | shiftKey), [.control, .shift]),
                // Shift only
                (UInt32(shiftKey), .shift),
            ]

            var idCounter: UInt32 = 1

            for (keyName, keyCode) in keyCodes {
                for (carbonMods, nsMods) in modifierCombos {
                    let hotKeyID = EventHotKeyID(signature: OSType(0x5353_4B52), id: idCounter)
                    var hotKeyRef: EventHotKeyRef?

                    let status = RegisterEventHotKey(
                        keyCode,
                        carbonMods,
                        hotKeyID,
                        GetApplicationEventTarget(),
                        0,
                        &hotKeyRef
                    )

                    if status == noErr, let ref = hotKeyRef {
                        // Store the actual key name and modifiers with the ID
                        hotKeyMap[idCounter] = (keyName, nsMods)
                        installedHotKeys.append((ref, keyCode, carbonMods))
                    }

                    idCounter += 1
                }
            }
        }


        private func handleHotKey(id: UInt32) {
            guard let (key, mods) = hotKeyMap[id] else { return }

            DispatchQueue.main.async { [weak self] in
                self?.onShortcutCaptured?(key, mods)
                self?.stopRecording()
            }
        }


        private func removeCarbonHandler() {
            // Unregister all hotkeys
            for (ref, _, _) in installedHotKeys {
                UnregisterEventHotKey(ref)
            }
            installedHotKeys.removeAll()
            hotKeyMap.removeAll()

            // Remove event handler
            if let handler = eventHandler {
                RemoveEventHandler(handler)
                eventHandler = nil
            }
        }
    }
}


// MARK: - Shortcut Recorder NSView

class ShortcutRecorderView: NSView {

    weak var coordinator: ShortcutRecorder.Coordinator?
    var isRecording: Bool = false {
        didSet { needsDisplay = true }
    }

    private var displayKey: String = ""
    private var displayModifiers: NSEvent.ModifierFlags = []
    private var trackingArea: NSTrackingArea?
    private var isHovered: Bool = false


    override var intrinsicContentSize: NSSize {
        NSSize(width: 240, height: 44)
    }


    override var acceptsFirstResponder: Bool { true }


    func updateDisplay(key: String, modifiers: NSEvent.ModifierFlags) {
        displayKey = key
        displayModifiers = modifiers
        needsDisplay = true
    }


    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let area = trackingArea {
            removeTrackingArea(area)
        }

        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }


    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }


    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }


    override func mouseDown(with event: NSEvent) {
        if !isRecording {
            window?.makeFirstResponder(self)
            coordinator?.startRecording()
            isRecording = true
            needsDisplay = true
        }
    }


    override func keyDown(with event: NSEvent) {
        // Escape cancels recording
        if event.keyCode == 53 && isRecording {
            coordinator?.stopRecording()
            isRecording = false
            needsDisplay = true
        }
    }


    private var shortcutString: String {
        var s = ""
        if displayModifiers.contains(.control) { s += "⌃" }
        if displayModifiers.contains(.option) { s += "⌥" }
        if displayModifiers.contains(.shift) { s += "⇧" }
        if displayModifiers.contains(.command) { s += "⌘" }
        s += displayKey.uppercased()
        return s
    }


    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Background
        let bgColor: NSColor
        if isRecording {
            bgColor = NSColor.controlAccentColor.withAlphaComponent(0.15)
        } else if isHovered {
            bgColor = NSColor.controlColor
        } else {
            bgColor = NSColor.controlBackgroundColor
        }

        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 8, yRadius: 8)
        bgColor.setFill()
        path.fill()

        // Border
        let borderColor = isRecording ? NSColor.controlAccentColor : NSColor.separatorColor
        borderColor.setStroke()
        path.lineWidth = isRecording ? 2 : 1
        path.stroke()

        // Main text
        let text = isRecording ? "Press shortcut..." : shortcutString
        let font = NSFont.systemFont(ofSize: 20, weight: .medium)
        let color = isRecording ? NSColor.controlAccentColor : NSColor.labelColor

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        let size = (text as NSString).size(withAttributes: attrs)
        let yOffset: CGFloat = isRecording ? 0 : 4
        let rect = NSRect(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2 + yOffset,
            width: size.width,
            height: size.height
        )

        (text as NSString).draw(in: rect, withAttributes: attrs)

        // Hint text
        let hint = isRecording ? "Press Esc to cancel" : "Click to record"
        let hintFont = NSFont.systemFont(ofSize: 10)
        let hintAttrs: [NSAttributedString.Key: Any] = [
            .font: hintFont,
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let hintSize = (hint as NSString).size(withAttributes: hintAttrs)
        let hintRect = NSRect(
            x: (bounds.width - hintSize.width) / 2,
            y: 2,
            width: hintSize.width,
            height: hintSize.height
        )
        (hint as NSString).draw(in: hintRect, withAttributes: hintAttrs)
    }
}

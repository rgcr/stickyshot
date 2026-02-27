/**
 * StickyWindowManager.swift
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 * Manages sticky preview windows with a maximum limit of 10
 */

import AppKit


class StickyWindowManager {

    private var previewWindows: [StickyPreviewWindow] = []


    // MARK: - Public Methods

    func addPreview(image: NSImage, frame: NSRect) {
        let maxPreviews = ConfigManager.shared.config.maxPreviews
        debugLog("Adding preview, current count: \(previewWindows.count), max: \(maxPreviews)", category: "StickyWindowManager")

        // Remove oldest if at limit
        while previewWindows.count >= maxPreviews {
            if let oldest = previewWindows.first {
                debugLog("Removing oldest preview", category: "StickyWindowManager")
                oldest.orderOut(nil)
                previewWindows.removeFirst()
            }
        }

        let config = ConfigManager.shared.config
        let showBorder = config.showBorder
        let borderColor = NSColor(hex: config.borderColor)
        let borderWidth = config.borderWidth
        debugLog("Creating preview window, showBorder=\(showBorder), borderWidth=\(borderWidth), frame=\(frame)", category: "StickyWindowManager")

        let previewWindow = StickyPreviewWindow(
            image: image,
            initialFrame: frame,
            showBorder: showBorder,
            borderColor: borderColor,
            borderWidth: borderWidth,
            onClose: { [weak self] window in
                self?.removeWindow(window)
            }
        )

        previewWindows.append(previewWindow)
        previewWindow.orderFrontRegardless()
        debugLog("Preview window displayed, total count: \(previewWindows.count)", category: "StickyWindowManager")
    }


    func closeAll() {
        for window in previewWindows {
            window.orderOut(nil)
        }
        previewWindows.removeAll()
    }


    // MARK: - Private Methods

    private func removeWindow(_ window: StickyPreviewWindow) {
        previewWindows.removeAll { $0 === window }
    }
}

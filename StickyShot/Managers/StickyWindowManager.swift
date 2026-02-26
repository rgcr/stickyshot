/**
 * StickyWindowManager.swift
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 * Manages sticky preview windows with a maximum limit of 10
 */

import AppKit


class StickyWindowManager {

    private let maxPreviews = 10
    private var previewWindows: [StickyPreviewWindow] = []


    // MARK: - Public Methods

    func addPreview(image: NSImage, frame: NSRect) {
        print("[StickyWindowManager] Adding preview, current count: \(previewWindows.count)")

        // Remove oldest if at limit
        while previewWindows.count >= maxPreviews {
            if let oldest = previewWindows.first {
                print("[StickyWindowManager] Removing oldest preview")
                oldest.orderOut(nil)
                previewWindows.removeFirst()
            }
        }

        let showBorder = ConfigManager.shared.config.showBlueBorder
        print("[StickyWindowManager] Creating preview window, showBorder=\(showBorder), frame=\(frame)")

        let previewWindow = StickyPreviewWindow(
            image: image,
            initialFrame: frame,
            showBlueBorder: showBorder,
            onClose: { [weak self] window in
                self?.removeWindow(window)
            }
        )

        previewWindows.append(previewWindow)
        previewWindow.orderFrontRegardless()
        print("[StickyWindowManager] Preview window displayed, total count: \(previewWindows.count)")
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

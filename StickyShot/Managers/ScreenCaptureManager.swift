/**
 * ScreenCaptureManager.swift
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 * Handles screen region selection and screenshot capture
 */

import AppKit
import CoreGraphics
import QuartzCore


class ScreenCaptureManager {

    private var selectionWindow: SelectionOverlayWindow?
    private var captureScreen: NSScreen?
    private var onCapture: ((NSImage, NSRect) -> Void)?
    private var isCapturing: Bool = false


    init(onCapture: @escaping (NSImage, NSRect) -> Void) {
        self.onCapture = onCapture
    }


    // MARK: - Public Methods

    func startSelection() {
        if isCapturing {
            print("[ScreenCaptureManager] Already capturing, ignoring")
            return
        }

        isCapturing = true
        print("[ScreenCaptureManager] Starting selection...")

        // Find screen where mouse is located
        let mouseLocation = NSEvent.mouseLocation
        var targetScreen = NSScreen.main

        for screen in NSScreen.screens {
            if screen.frame.contains(mouseLocation) {
                targetScreen = screen
                break
            }
        }

        guard let screen = targetScreen else {
            print("[ScreenCaptureManager] ERROR: No screen found")
            isCapturing = false
            return
        }

        print("[ScreenCaptureManager] Screen frame: \(screen.frame), mouse at: \(mouseLocation)")

        DispatchQueue.main.async { [weak self] in
            self?.showSelectionWindow(screen: screen)
        }
    }


    private func showSelectionWindow(screen: NSScreen) {
        captureScreen = screen

        print("[ScreenCaptureManager] Creating selection window for screen: \(screen.frame)")

        let window = SelectionOverlayWindow(
            screen: screen,
            onSelection: { [weak self] rect in
                guard let screenFrame = self?.captureScreen?.frame else {
                    self?.onSelectionCancel()
                    return
                }
                // Convert selection rect from screen-relative to absolute coordinates
                let absoluteRect = NSRect(
                    x: screenFrame.origin.x + rect.origin.x,
                    y: screenFrame.origin.y + rect.origin.y,
                    width: rect.width,
                    height: rect.height
                )
                self?.onSelectionComplete(absoluteRect)
            },
            onCancel: { [weak self] in
                self?.onSelectionCancel()
            }
        )

        selectionWindow = window

        // Set the window frame explicitly to the target screen
        window.setFrame(screen.frame, display: true)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        print("[ScreenCaptureManager] Selection window shown on screen: \(screen.frame)")
    }


    private func onSelectionComplete(_ rect: NSRect) {
        print("[ScreenCaptureManager] Selection completed: \(rect)")

        // Store window reference and clear immediately
        let window = selectionWindow
        selectionWindow = nil
        captureScreen = nil

        // Hide window
        window?.orderOut(nil)

        // Force screen refresh
        CATransaction.flush()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

        // Cleanup window
        window?.cleanup()
        window?.close()

        // Capture after window is fully gone
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.performCapture(rect: rect)
            self?.isCapturing = false
        }
    }


    private func onSelectionCancel() {
        print("[ScreenCaptureManager] Selection cancelled")
        selectionWindow?.orderOut(nil)
        selectionWindow?.cleanup()
        selectionWindow?.close()
        selectionWindow = nil
        captureScreen = nil
        isCapturing = false
    }


    private func performCapture(rect: NSRect) {
        print("[ScreenCaptureManager] Performing capture for rect: \(rect)")

        // Get the primary screen height for coordinate conversion
        guard let primaryScreen = NSScreen.screens.first else {
            print("[ScreenCaptureManager] ERROR: No screens found")
            return
        }

        let primaryHeight = primaryScreen.frame.height

        // Convert from NSScreen coordinates (bottom-left) to CGWindow coordinates (top-left)
        let cgRect = CGRect(
            x: rect.origin.x,
            y: primaryHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )

        print("[ScreenCaptureManager] Capturing CGRect: \(cgRect)")

        guard let cgImage = CGWindowListCreateImage(
            cgRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            print("[ScreenCaptureManager] ERROR: Failed to capture - check Screen Recording permission")
            return
        }

        print("[ScreenCaptureManager] Captured image: \(cgImage.width)x\(cgImage.height)")

        let nsImage = NSImage(cgImage: cgImage, size: rect.size)
        print("[ScreenCaptureManager] Calling onCapture callback...")

        DispatchQueue.main.async { [weak self] in
            self?.onCapture?(nsImage, rect)
            print("[ScreenCaptureManager] Capture complete")
        }
    }
}

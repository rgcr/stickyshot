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
    private var onCancel: (() -> Void)?
    private var isCapturing: Bool = false


    init(onCapture: @escaping (NSImage, NSRect) -> Void, onCancel: @escaping () -> Void) {
        self.onCapture = onCapture
        self.onCancel = onCancel
    }


    // MARK: - Public Methods

    func startSelection() {
        if isCapturing {
            debugLog("Already capturing, ignoring", category: "ScreenCaptureManager")
            return
        }

        isCapturing = true
        debugLog("Starting selection...", category: "ScreenCaptureManager")

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
            debugLog("ERROR: No screen found", category: "ScreenCaptureManager")
            isCapturing = false
            return
        }

        debugLog("Screen frame: \(screen.frame), mouse at: \(mouseLocation)", category: "ScreenCaptureManager")

        DispatchQueue.main.async { [weak self] in
            self?.showSelectionWindow(screen: screen)
        }
    }


    private func showSelectionWindow(screen: NSScreen) {
        captureScreen = screen

        debugLog("Creating selection window for screen: \(screen.frame)", category: "ScreenCaptureManager")

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
        debugLog("Selection window shown on screen: \(screen.frame)", category: "ScreenCaptureManager")
    }


    private func onSelectionComplete(_ rect: NSRect) {
        debugLog("Selection completed: \(rect)", category: "ScreenCaptureManager")

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
        debugLog("Selection cancelled", category: "ScreenCaptureManager")
        selectionWindow?.orderOut(nil)
        selectionWindow?.cleanup()
        selectionWindow?.close()
        selectionWindow = nil
        captureScreen = nil
        isCapturing = false
        onCancel?()
    }


    private func performCapture(rect: NSRect) {
        debugLog("Performing capture for rect: \(rect)", category: "ScreenCaptureManager")

        // Get the primary screen height for coordinate conversion
        guard let primaryScreen = NSScreen.screens.first else {
            debugLog("ERROR: No screens found", category: "ScreenCaptureManager")
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

        debugLog("Capturing CGRect: \(cgRect)", category: "ScreenCaptureManager")

        guard let cgImage = CGWindowListCreateImage(
            cgRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            debugLog("ERROR: Failed to capture - check Screen Recording permission", category: "ScreenCaptureManager")
            return
        }

        debugLog("Captured image: \(cgImage.width)x\(cgImage.height)", category: "ScreenCaptureManager")

        let nsImage = NSImage(cgImage: cgImage, size: rect.size)
        debugLog("Calling onCapture callback...", category: "ScreenCaptureManager")

        DispatchQueue.main.async { [weak self] in
            self?.onCapture?(nsImage, rect)
            debugLog("Capture complete", category: "ScreenCaptureManager")
        }
    }
}

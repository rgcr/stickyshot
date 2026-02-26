/**
 * SelectionOverlayWindow.swift
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 * Full-screen transparent overlay for region selection with crosshair cursor
 */

import AppKit


class SelectionOverlayWindow: NSPanel {

    private var selectionView: SelectionOverlayView?


    init(screen: NSScreen, onSelection: @escaping (NSRect) -> Void, onCancel: @escaping () -> Void) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .screenSaver
        isOpaque = false
        backgroundColor = NSColor.black.withAlphaComponent(0.3)
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = SelectionOverlayView(frame: screen.frame)
        view.selectionCallback = onSelection
        view.cancelCallback = onCancel
        selectionView = view

        contentView = view
    }


    override var canBecomeKey: Bool {
        return true
    }


    override var canBecomeMain: Bool {
        return true
    }


    func cleanup() {
        selectionView?.selectionCallback = nil
        selectionView?.cancelCallback = nil
        selectionView = nil
    }
}


// MARK: - Selection Overlay View

class SelectionOverlayView: NSView {

    var selectionCallback: ((NSRect) -> Void)?
    var cancelCallback: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var trackingArea: NSTrackingArea?
    private var hasCompleted: Bool = false


    override init(frame: NSRect) {
        super.init(frame: frame)
        setupTrackingArea()
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    private func setupTrackingArea() {
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }


    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }


    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.black.withAlphaComponent(0.3).setFill()
        dirtyRect.fill()

        guard let start = startPoint, let current = currentPoint else { return }

        let selectionRect = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )

        NSColor.clear.setFill()
        selectionRect.fill()

        NSColor.white.setStroke()
        let borderPath = NSBezierPath(rect: selectionRect)
        borderPath.lineWidth = 1.0
        borderPath.stroke()

        NSColor.gray.setStroke()
        let dashedPath = NSBezierPath(rect: selectionRect.insetBy(dx: 1, dy: 1))
        dashedPath.lineWidth = 1.0
        dashedPath.setLineDash([4, 4], count: 2, phase: 0)
        dashedPath.stroke()
    }


    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        needsDisplay = true
    }


    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }


    override func mouseUp(with event: NSEvent) {
        guard !hasCompleted else { return }

        guard let start = startPoint, let current = currentPoint else {
            completeWithCancel()
            return
        }

        let selectionRect = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )

        if selectionRect.width < 10 || selectionRect.height < 10 {
            completeWithCancel()
            return
        }

        completeWithSelection(selectionRect)
    }


    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            completeWithCancel()
        }
    }


    override var acceptsFirstResponder: Bool {
        return true
    }


    private func completeWithSelection(_ rect: NSRect) {
        guard !hasCompleted else { return }
        hasCompleted = true

        let callback = selectionCallback
        selectionCallback = nil
        cancelCallback = nil

        callback?(rect)
    }


    private func completeWithCancel() {
        guard !hasCompleted else { return }
        hasCompleted = true

        let callback = cancelCallback
        selectionCallback = nil
        cancelCallback = nil

        callback?()
    }
}

/**
 * StickyPreviewWindow.swift
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 * Floating always-on-top preview window that displays captured screenshot
 * with annotation support (line, arrow, square, circle)
 */

import AppKit


// MARK: - Drawing Types

enum DrawingTool {
    case none
    case line
    case arrow
    case square
    case circle
}

struct DrawnShape {
    let tool: DrawingTool
    let start: NSPoint
    let end: NSPoint
    let color: NSColor
}


// MARK: - StickyPreviewWindow

class StickyPreviewWindow: NSPanel {

    private let previewImage: NSImage
    private let showBorder: Bool
    private let borderColor: NSColor
    private let borderWidth: CGFloat
    private var onCloseCallback: ((StickyPreviewWindow) -> Void)?
    private var imageView: NSImageView!
    private var drawingView: DrawingOverlayView!


    init(image: NSImage, initialFrame: NSRect, showBorder: Bool, borderColor: NSColor, borderWidth: Int, onClose: @escaping (StickyPreviewWindow) -> Void) {
        self.previewImage = image
        self.showBorder = showBorder
        self.borderColor = borderColor
        self.borderWidth = showBorder ? CGFloat(borderWidth) : 0.0
        self.onCloseCallback = onClose

        let borderWidth: CGFloat = self.borderWidth
        let windowFrame = NSRect(
            x: initialFrame.origin.x - borderWidth,
            y: initialFrame.origin.y - borderWidth,
            width: initialFrame.width + (borderWidth * 2),
            height: initialFrame.height + (borderWidth * 2)
        )

        super.init(
            contentRect: windowFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = false
        isMovable = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        setupContent(borderWidth: borderWidth)
        setupMenu()

        debugLog("Window initialized", category: "StickyPreviewWindow")
    }


    private func setupContent(borderWidth: CGFloat) {
        let containerView = NSView(frame: NSRect(origin: .zero, size: frame.size))
        containerView.wantsLayer = true

        if showBorder {
            containerView.layer?.backgroundColor = borderColor.cgColor
        }

        let imageRect: NSRect
        if showBorder {
            imageRect = NSRect(
                x: borderWidth,
                y: borderWidth,
                width: frame.width - (borderWidth * 2),
                height: frame.height - (borderWidth * 2)
            )
        } else {
            imageRect = NSRect(origin: .zero, size: frame.size)
        }

        imageView = NSImageView(frame: imageRect)
        imageView.image = previewImage
        imageView.imageScaling = .scaleNone
        imageView.wantsLayer = true
        containerView.addSubview(imageView)
        
        // Drawing overlay on top of image
        drawingView = DrawingOverlayView(frame: imageRect)
        drawingView.parentWindow = self
        containerView.addSubview(drawingView)

        contentView = containerView
    }
    
    
    private func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Copy", action: #selector(copyAction), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "Save", action: #selector(saveAction), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        
        let undoItem = NSMenuItem(title: "Undo", action: #selector(undoAction), keyEquivalent: "z")
        undoItem.tag = 1
        menu.addItem(undoItem)
        
        let clearItem = NSMenuItem(title: "Clear All Drawings", action: #selector(clearAllAction), keyEquivalent: "")
        clearItem.tag = 2
        menu.addItem(clearItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Draw Line", action: #selector(drawLine), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Draw Arrow", action: #selector(drawArrow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Draw Square", action: #selector(drawSquare), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Draw Circle", action: #selector(drawCircle), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Close", action: #selector(closeAction), keyEquivalent: ""))
        
        menu.delegate = self
        drawingView.menu = menu
    }
    
    
    @objc private func copyAction() {
        copyToClipboard()
    }
    
    @objc private func saveAction() {
        saveToFile()
    }
    
    @objc private func undoAction() {
        drawingView.undo()
    }
    
    @objc private func clearAllAction() {
        drawingView.clearAll()
    }
    
    @objc private func drawLine() {
        drawingView.currentTool = .line
        NSCursor.crosshair.set()
    }
    
    @objc private func drawArrow() {
        drawingView.currentTool = .arrow
        NSCursor.crosshair.set()
    }
    
    @objc private func drawSquare() {
        drawingView.currentTool = .square
        NSCursor.crosshair.set()
    }
    
    @objc private func drawCircle() {
        drawingView.currentTool = .circle
        NSCursor.crosshair.set()
    }
    
    @objc private func closeAction() {
        closePreview()
    }


    override var canBecomeKey: Bool {
        return true
    }


    override var canBecomeMain: Bool {
        return false
    }


    override func keyDown(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        switch event.keyCode {
        case 53: // Escape
            if drawingView.currentTool != .none {
                drawingView.currentTool = .none
                NSCursor.arrow.set()
            } else {
                closePreview()
            }

        case 8: // C key
            if modifiers.contains(.command) {
                copyToClipboard()
            }

        case 1: // S key
            if modifiers.contains(.command) {
                saveToFile()
            }
            
        case 6: // Z key
            if modifiers.contains(.command) {
                undoAction()
            }

        default:
            super.keyDown(with: event)
        }
    }


    override func scrollWheel(with event: NSEvent) {
        let delta = event.deltaY * 0.02
        let newOpacity = max(0.3, min(1.0, self.alphaValue + delta))
        self.alphaValue = newOpacity
    }
    
    
    private func compositeImage() -> NSImage {
        let size = previewImage.size
        let image = NSImage(size: size)
        
        image.lockFocus()
        previewImage.draw(in: NSRect(origin: .zero, size: size))
        
        // Draw all shapes
        let drawColor = NSColor(hex: ConfigManager.shared.config.drawColor)
        drawColor.setStroke()
        
        for shape in drawingView.shapes {
            let path = NSBezierPath()
            path.lineWidth = 2.0
            
            switch shape.tool {
            case .line:
                path.move(to: shape.start)
                path.line(to: shape.end)
                path.stroke()
                
            case .arrow:
                path.move(to: shape.start)
                path.line(to: shape.end)
                path.stroke()
                drawArrowhead(at: shape.end, from: shape.start, color: drawColor)
                
            case .square:
                let rect = rectFromPoints(shape.start, shape.end)
                path.appendRect(rect)
                path.stroke()
                
            case .circle:
                let rect = rectFromPoints(shape.start, shape.end)
                path.appendOval(in: rect)
                path.stroke()
                
            case .none:
                break
            }
        }
        
        image.unlockFocus()
        return image
    }
    
    
    private func drawArrowhead(at point: NSPoint, from start: NSPoint, color: NSColor) {
        let arrowLength: CGFloat = 12.0
        let arrowAngle: CGFloat = .pi / 6
        
        let angle = atan2(point.y - start.y, point.x - start.x)
        
        let path = NSBezierPath()
        path.move(to: point)
        path.line(to: NSPoint(
            x: point.x - arrowLength * cos(angle - arrowAngle),
            y: point.y - arrowLength * sin(angle - arrowAngle)
        ))
        path.move(to: point)
        path.line(to: NSPoint(
            x: point.x - arrowLength * cos(angle + arrowAngle),
            y: point.y - arrowLength * sin(angle + arrowAngle)
        ))
        
        path.lineWidth = 2.0
        color.setStroke()
        path.stroke()
    }
    
    
    private func rectFromPoints(_ p1: NSPoint, _ p2: NSPoint) -> NSRect {
        return NSRect(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p2.x - p1.x),
            height: abs(p2.y - p1.y)
        )
    }


    private func copyToClipboard() {
        let image = compositeImage()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        showFeedback("Copied!")
    }


    private func saveToFile() {
        let image = compositeImage()
        let config = ConfigManager.shared.config
        let format = config.exportFormat
        let ext = format == "jpeg" ? "jpg" : format
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "StickyShot_\(timestamp).\(ext)"

        let saveDir = config.saveDirectory
        let dirURL = URL(fileURLWithPath: saveDir)
        
        if !FileManager.default.fileExists(atPath: saveDir) {
            do {
                try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
            } catch {
                debugLog("Failed to create directory: \(error)", category: "StickyPreviewWindow")
                return
            }
        }

        let fileURL = dirURL.appendingPathComponent(filename)

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            debugLog("Failed to get image data", category: "StickyPreviewWindow")
            return
        }
        
        let imageData: Data?
        if format == "jpeg" {
            imageData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 1.0])
        } else {
            imageData = bitmapRep.representation(using: .png, properties: [:])
        }
        
        guard let data = imageData else {
            debugLog("Failed to convert image to \(format.uppercased())", category: "StickyPreviewWindow")
            return
        }

        do {
            try data.write(to: fileURL)
            showFeedback("Saved!")
        } catch {
            debugLog("Failed to save image: \(error)", category: "StickyPreviewWindow")
        }
    }


    private func closePreview() {
        let callback = onCloseCallback
        onCloseCallback = nil
        callback?(self)
        orderOut(nil)
    }


    private func showFeedback(_ message: String) {
        guard let view = contentView else { return }

        let label = NSTextField(labelWithString: message)
        label.font = NSFont.boldSystemFont(ofSize: 14)
        label.textColor = .black
        label.drawsBackground = false
        label.isBordered = false
        label.isEditable = false
        label.alignment = .center
        label.wantsLayer = true
        label.layer?.backgroundColor = NSColor.orange.cgColor
        label.layer?.cornerRadius = 4
        label.sizeToFit()

        let labelWidth = label.bounds.width + 16
        let labelHeight = label.bounds.height + 8
        label.frame = NSRect(
            x: (view.bounds.width - labelWidth) / 2,
            y: (view.bounds.height - labelHeight) / 2,
            width: labelWidth,
            height: labelHeight
        )

        view.addSubview(label)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak label] in
            label?.removeFromSuperview()
        }
    }
}


// MARK: - NSMenuDelegate

extension StickyPreviewWindow: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        let hasDrawings = !drawingView.shapes.isEmpty
        if let undoItem = menu.item(withTag: 1) {
            undoItem.isEnabled = hasDrawings
        }
        if let clearItem = menu.item(withTag: 2) {
            clearItem.isEnabled = hasDrawings
        }
    }
}


// MARK: - Drawing Overlay View

class DrawingOverlayView: NSView {
    
    var currentTool: DrawingTool = .none
    var shapes: [DrawnShape] = []
    weak var parentWindow: StickyPreviewWindow?
    
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    
    override var mouseDownCanMoveWindow: Bool {
        return currentTool == .none
    }
    
    
    override func mouseDown(with event: NSEvent) {
        if currentTool == .none {
            parentWindow?.performDrag(with: event)
        } else {
            startPoint = convert(event.locationInWindow, from: nil)
            currentPoint = startPoint
        }
    }
    
    
    override func mouseDragged(with event: NSEvent) {
        if currentTool != .none {
            currentPoint = convert(event.locationInWindow, from: nil)
            needsDisplay = true
        }
    }
    
    
    override func mouseUp(with event: NSEvent) {
        guard currentTool != .none,
              let start = startPoint,
              let end = currentPoint else { return }
        
        let drawColor = NSColor(hex: ConfigManager.shared.config.drawColor)
        let shape = DrawnShape(tool: currentTool, start: start, end: end, color: drawColor)
        shapes.append(shape)
        
        // Auto-exit draw mode after each shape
        currentTool = .none
        NSCursor.arrow.set()
        
        startPoint = nil
        currentPoint = nil
        needsDisplay = true
    }
    
    
    func undo() {
        if !shapes.isEmpty {
            shapes.removeLast()
            needsDisplay = true
        }
    }
    
    
    func clearAll() {
        if !shapes.isEmpty {
            shapes.removeAll()
            needsDisplay = true
        }
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let drawColor = NSColor(hex: ConfigManager.shared.config.drawColor)
        drawColor.setStroke()
        
        // Draw completed shapes
        for shape in shapes {
            drawShape(shape)
        }
        
        // Draw current shape being drawn
        if let start = startPoint, let current = currentPoint, currentTool != .none {
            let tempShape = DrawnShape(tool: currentTool, start: start, end: current, color: drawColor)
            drawShape(tempShape)
        }
    }
    
    
    private func drawShape(_ shape: DrawnShape) {
        let path = NSBezierPath()
        path.lineWidth = 2.0
        shape.color.setStroke()
        
        switch shape.tool {
        case .line:
            path.move(to: shape.start)
            path.line(to: shape.end)
            path.stroke()
            
        case .arrow:
            path.move(to: shape.start)
            path.line(to: shape.end)
            path.stroke()
            drawArrowhead(at: shape.end, from: shape.start, color: shape.color)
            
        case .square:
            let rect = rectFromPoints(shape.start, shape.end)
            path.appendRect(rect)
            path.stroke()
            
        case .circle:
            let rect = rectFromPoints(shape.start, shape.end)
            path.appendOval(in: rect)
            path.stroke()
            
        case .none:
            break
        }
    }
    
    
    private func drawArrowhead(at point: NSPoint, from start: NSPoint, color: NSColor) {
        let arrowLength: CGFloat = 12.0
        let arrowAngle: CGFloat = .pi / 6
        
        let angle = atan2(point.y - start.y, point.x - start.x)
        
        let path = NSBezierPath()
        path.move(to: point)
        path.line(to: NSPoint(
            x: point.x - arrowLength * cos(angle - arrowAngle),
            y: point.y - arrowLength * sin(angle - arrowAngle)
        ))
        path.move(to: point)
        path.line(to: NSPoint(
            x: point.x - arrowLength * cos(angle + arrowAngle),
            y: point.y - arrowLength * sin(angle + arrowAngle)
        ))
        
        path.lineWidth = 2.0
        color.setStroke()
        path.stroke()
    }
    
    
    private func rectFromPoints(_ p1: NSPoint, _ p2: NSPoint) -> NSRect {
        return NSRect(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p2.x - p1.x),
            height: abs(p2.y - p1.y)
        )
    }
}

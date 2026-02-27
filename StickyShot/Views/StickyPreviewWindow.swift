/**
 * StickyPreviewWindow.swift
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 * Floating always-on-top preview window that displays captured screenshot
 */

import AppKit


class StickyPreviewWindow: NSPanel {

    private let previewImage: NSImage
    private let showBorder: Bool
    private let borderColor: NSColor
    private let borderWidth: CGFloat
    private var onCloseCallback: ((StickyPreviewWindow) -> Void)?
    private var imageView: NSImageView!


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
        isMovableByWindowBackground = true
        isMovable = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Enable dragging
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        setupContent(borderWidth: borderWidth)

        debugLog("Window initialized", category: "StickyPreviewWindow")
    }


    private func setupContent(borderWidth: CGFloat) {
        let containerView = DraggableView(frame: NSRect(origin: .zero, size: frame.size))
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

        contentView = containerView
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
            closePreview()

        case 8: // C key
            if modifiers.contains(.command) {
                copyToClipboard()
            }

        case 1: // S key
            if modifiers.contains(.command) {
                saveToDesktop()
            }

        default:
            super.keyDown(with: event)
        }
    }


    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([previewImage])
        showFeedback("Copied!")
    }


    private func saveToDesktop() {
        let config = ConfigManager.shared.config
        let format = config.exportFormat
        let ext = format == "jpeg" ? "jpg" : format
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "StickyShot_\(timestamp).\(ext)"

        let saveDir = config.saveDirectory
        let dirURL = URL(fileURLWithPath: saveDir)
        
        // Create directory if needed
        if !FileManager.default.fileExists(atPath: saveDir) {
            do {
                try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
            } catch {
                debugLog("Failed to create directory: \(error)", category: "StickyPreviewWindow")
                return
            }
        }

        let fileURL = dirURL.appendingPathComponent(filename)

        guard let tiffData = previewImage.tiffRepresentation,
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
        label.textColor = .white
        label.backgroundColor = NSColor.black.withAlphaComponent(0.7)
        label.isBordered = false
        label.isEditable = false
        label.alignment = .center
        label.wantsLayer = true
        label.layer?.cornerRadius = 4
        label.sizeToFit()

        label.frame = NSRect(
            x: (view.bounds.width - label.bounds.width - 16) / 2,
            y: (view.bounds.height - label.bounds.height - 8) / 2,
            width: label.bounds.width + 16,
            height: label.bounds.height + 8
        )

        view.addSubview(label)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak label] in
            label?.removeFromSuperview()
        }
    }
}


// MARK: - Draggable View

class DraggableView: NSView {

    override var mouseDownCanMoveWindow: Bool {
        return true
    }


    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

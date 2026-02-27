/**
 * ColorExtensions.swift
 * ~~~~~~~~~~~~~~~~~~~~~~
 *
 * Extensions for color conversion between hex strings and NSColor/Color
 */

import AppKit
import SwiftUI


extension NSColor {

    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }


    var hexString: String {
        guard let rgbColor = usingColorSpace(.sRGB) else { return "#000000" }

        let r = Int(rgbColor.redComponent * 255)
        let g = Int(rgbColor.greenComponent * 255)
        let b = Int(rgbColor.blueComponent * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}


extension Color {

    init(hex: String) {
        self.init(NSColor(hex: hex))
    }
}

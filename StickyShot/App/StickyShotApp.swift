/**
 * StickyShotApp.swift
 * ~~~~~~~~~~~~~~~~~~~~
 *
 * Main entry point for StickyShot menu bar application
 */

import SwiftUI


@main
struct StickyShotApp {

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

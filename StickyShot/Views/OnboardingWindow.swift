/**
 * OnboardingWindow.swift
 * ~~~~~~~~~~~~~~~~~~~~~~~
 *
 * First-launch onboarding window to guide users through permissions setup
 */

import SwiftUI
import AppKit


struct OnboardingView: View {
    @State private var accessibilityGranted = false
    @State private var screenRecordingGranted = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("Welcome to StickyShot")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Screenshots that stay on top")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Permissions
            VStack(alignment: .leading, spacing: 16) {
                Text("StickyShot needs two permissions to work:")
                    .font(.system(size: 13, weight: .medium))
                
                // Accessibility
                HStack(spacing: 12) {
                    Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(accessibilityGranted ? .green : .secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility")
                            .font(.system(size: 13, weight: .medium))
                        Text("Required for global hotkey")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Open Settings") {
                        openAccessibilitySettings()
                    }
                    .controlSize(.small)
                    .disabled(accessibilityGranted)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Screen Recording
                HStack(spacing: 12) {
                    Image(systemName: screenRecordingGranted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(screenRecordingGranted ? .green : .secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screen Recording")
                            .font(.system(size: 13, weight: .medium))
                        Text("Required to capture screenshots")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Open Settings") {
                        openScreenRecordingSettings()
                    }
                    .controlSize(.small)
                    .disabled(screenRecordingGranted)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            
            Text("StickyShot does not collect any data.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            
            Spacer()
            
            // Footer
            VStack(spacing: 12) {
                if accessibilityGranted && screenRecordingGranted {
                    Text("✓ All permissions granted!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.green)
                } else {
                    Text("Grant permissions above, then click Continue")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Button("Skip for Now") {
                        onComplete()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Continue") {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!accessibilityGranted || !screenRecordingGranted)
                }
            }
            .padding(20)
        }
        .frame(width: 420, height: 550)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            checkPermissions()
        }
        .onReceive(timer) { _ in
            checkPermissions()
        }
    }
    
    
    private func checkPermissions() {
        accessibilityGranted = AXIsProcessTrusted()
        screenRecordingGranted = CGPreflightScreenCaptureAccess()
    }
    
    
    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    
    private func openScreenRecordingSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
}


class OnboardingWindowController {
    private var window: NSWindow?
    
    func show(onComplete: @escaping () -> Void) {
        let onboardingView = OnboardingView(onComplete: { [weak self] in
            self?.window?.close()
            self?.window = nil
            onComplete()
        })
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 550),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window?.title = "Welcome to StickyShot"
        window?.contentView = NSHostingView(rootView: onboardingView)
        window?.center()
        window?.isReleasedWhenClosed = false
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

//
//  ScreenTimeDesktopApp.swift
//  ScreenTimeDesktop
//
//  Created by Donghan Hu on 1/30/25.
//

import SwiftUI
import AppKit

@main
struct ScreenTimeDesktopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView() // No traditional window; this is a menu bar app
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var trackMenuItem: NSMenuItem?
    var isTracking = false
    let tracker = Tracking() // Create an instance of Tracker
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusBarIcon()
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Check WireGuard", action: #selector(checkWireGuard), keyEquivalent: "c"))
        
        trackMenuItem = NSMenuItem(title: "Track", action: #selector(trackAction), keyEquivalent: "t")
        trackMenuItem?.isEnabled = isWireGuardInstalled()
        menu.addItem(trackMenuItem!)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    func updateStatusBarIcon() {
        if let button = statusItem?.button {
            let iconName = isTracking ? "waveform" : "network"
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Tracking Indicator")
        }
    }
    
    @objc func checkWireGuard() {
        let isInstalled = isWireGuardInstalled()
        if isInstalled {
            showAlert(message: "WireGuard is already installed.", informativeText: "You don't need to install WireGuard again.")
        } else {
            showAlert(message: "WireGuard is not installed.", informativeText: "The installation will now begin.")
            installWireGuard()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.trackMenuItem?.isEnabled = self?.isWireGuardInstalled() ?? false
            }
        }
    }
    
    @objc func trackAction() {
        if !isWireGuardInstalled() {
            showAlert(message: "WireGuard Not Installed", informativeText: "Please install WireGuard first by clicking 'Check WireGuard'.")
            return
        }
        
        isTracking.toggle()
        updateStatusBarIcon()
        
        if isTracking {
            trackMenuItem?.title = "Stop"
            tracker.startTracking() // Start tracking
            showAlert(message: "Tracking Started", informativeText: "Tracking is now active.")
        } else {
            trackMenuItem?.title = "Track"
            tracker.stopTracking() // Stop tracking
            showAlert(message: "Tracking Stopped", informativeText: "Tracking has been stopped.")
        }
    }
    
    func isWireGuardInstalled() -> Bool {
        let fileManager = FileManager.default
        
        // Check if wg exists in common locations
        let possiblePaths = [
            "/opt/homebrew/bin/wg",  // Apple Silicon Homebrew
            "/usr/local/bin/wg"      // Intel Mac Homebrew
        ]
        
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                print("WireGuard found at \(path)")
                return true
            }
        }
        
        print("WireGuard not found.")
        return false
    }
    
    
//    func installWireGuard() {
//        let command = """
//            if ! command -v wg &> /dev/null; then /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; /opt/homebrew/bin/brew install wireguard-tools || /usr/local/bin/brew install wireguard-tools; fi
//            """
//        
//        // Copy command to clipboard
//        let pasteboard = NSPasteboard.general
//        pasteboard.clearContents()
//        pasteboard.setString(command, forType: .string)
//        
//        // Show alert
//        let alert = NSAlert()
//        alert.messageText = "WireGuard Installation Required"
//        alert.informativeText = "WireGuard is not installed. The installation command has been copied to your clipboard. Please open Terminal and paste the command to install WireGuard."
//        alert.alertStyle = .warning
//        alert.addButton(withTitle: "Open Terminal")
//        alert.addButton(withTitle: "Cancel")
//        
//        let response = alert.runModal()
//        if response == .alertFirstButtonReturn {
//            openTerminal()
//        }
//    }
    func installWireGuard() {
        let installCommand = """
        if ! command -v wg &> /dev/null; then /bin/bash -c \\"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\\"; /opt/homebrew/bin/brew install wireguard-tools || /usr/local/bin/brew install wireguard-tools; fi
        """

        let appleScript = """
        tell application "Terminal"
            activate
            do script "\(installCommand)"
        end tell
        """

        executeAppleScript(script: appleScript)
    }


    func executeAppleScript(script: String) {
        let process = Process()
        let pipe = Pipe()
        
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", script]
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print(output)
            }
        } catch {
            print("Error executing AppleScript: \(error.localizedDescription)")
        }
    }
    
    
    
    
    
    
    func openTerminal() {
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = ["-a", "Terminal"]
        
        do {
            try process.run()
        } catch {
            print("Error opening Terminal: \(error.localizedDescription)")
        }
    }
    
    
    
    func showAlert(message: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

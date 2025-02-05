//
//  Tracking.swift
//  ScreenTimeDesktop
//
//  Created by Donghan Hu on 1/30/25.
//

import Foundation
import AppKit

class Tracking {
    private var timer: Timer?
    private let fileManager = FileManager.default
    private let csvFilePath: String

    init() {
        // Define the path for the CSV file in Documents/ScreenTime/
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let screenTimeFolder = documentsPath.appendingPathComponent("ScreenTime")
        let csvFile = screenTimeFolder.appendingPathComponent("screentime_log.csv")
        self.csvFilePath = csvFile.path

        // Ensure the directory exists
        createDirectoryIfNeeded(at: screenTimeFolder)
        // Ensure the CSV file has headers if it doesn't exist
        createCSVIfNeeded()
    }

    func startTracking() {
        if !checkAccessibilityPermissions() {
            print("Accessibility permissions are not enabled.")
            return
        }

        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(trackFrontmostApplication), userInfo: nil, repeats: true)
        print("Tracking started...")
    }

    func stopTracking() {
        timer?.invalidate()
        timer = nil
        print("Tracking stopped.")
    }

    @objc private func trackFrontmostApplication() {
        let timestamp = getCurrentTimestamp()
        let appName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown App"
        let windowTitle = getActiveWindowTitle() ?? "Unknown Window Title"

        print("Timestamp: \(timestamp), Frontmost App: \(appName), Window Title: \(windowTitle)")

        // Save to CSV
        saveToCSV(timestamp: timestamp, appName: appName, windowTitle: windowTitle)
    }

    private func getActiveWindowTitle() -> String? {
        guard checkAccessibilityPermissions() else {
            print("Accessibility permissions are required to get the window title.")
            return nil
        }

        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let appPID = frontApp.processIdentifier
        let appElement = AXUIElementCreateApplication(appPID)

        var window: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &window)

        if result == .success, let windowElement = window {
            var title: AnyObject?
            let titleResult = AXUIElementCopyAttributeValue(windowElement as! AXUIElement, kAXTitleAttribute as CFString, &title)
            if titleResult == .success, let windowTitle = title as? String {
                return windowTitle
            }
        }

        return nil
    }

    private func checkAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let isTrusted = AXIsProcessTrustedWithOptions(options)

        if !isTrusted {
            print("App does not have Accessibility permissions.")
        }

        return isTrusted
    }

    private func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }

    private func createDirectoryIfNeeded(at path: URL) {
        if !fileManager.fileExists(atPath: path.path) {
            do {
                try fileManager.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
                print("Created directory: \(path.path)")
            } catch {
                print("Error creating directory: \(error.localizedDescription)")
            }
        }
    }

    private func createCSVIfNeeded() {
        if !fileManager.fileExists(atPath: csvFilePath) {
            let header = "Timestamp,Application Name,Window Title\n"
            do {
                try header.write(toFile: csvFilePath, atomically: true, encoding: .utf8)
                print("Created new CSV file with headers.")
            } catch {
                print("Error creating CSV file: \(error.localizedDescription)")
            }
        }
    }

    private func saveToCSV(timestamp: String, appName: String, windowTitle: String) {
        let row = "\"\(timestamp)\",\"\(appName)\",\"\(windowTitle)\"\n"
        if let handle = FileHandle(forWritingAtPath: csvFilePath) {
            handle.seekToEndOfFile()
            if let data = row.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        } else {
            do {
                try row.write(toFile: csvFilePath, atomically: true, encoding: .utf8)
            } catch {
                print("Error writing to CSV file: \(error.localizedDescription)")
            }
        }
    }
}

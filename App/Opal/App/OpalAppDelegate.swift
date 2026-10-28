//
//  OpalAppDelegate.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit
import OpalCore

@MainActor
final class OpalAppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Constants

    private enum Constants {
        static let snapshotDelay = Duration.seconds(5)
    }

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let name = AppDependencies.shared.launchAppearance {
            NSApp.appearance = NSAppearance(named: name)
        }
        #if DEBUG
            if let url = AppDependencies.shared.launchSnapshotURL {
                snapshotAndQuit(to: url)
            }
        #endif
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Task {
            await AppDependencies.shared.services.notes.flush()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    func applicationWillResignActive(_ notification: Notification) {
        Task {
            await AppDependencies.shared.services.notes.flush()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // MARK: - Snapshot

    #if DEBUG
        private func write(_ view: NSView?, to url: URL) {
            guard let view, let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
                AppLog.error("The snapshot view is missing")
                return
            }

            view.cacheDisplay(in: view.bounds, to: bitmap)
            do {
                try bitmap.representation(using: .png, properties: [:])?.write(to: url)
            } catch {
                AppLog.error("Writing the snapshot failed: \(error)")
            }
        }

        private func snapshotAndQuit(to url: URL) {
            Task {
                try? await Task.sleep(for: Constants.snapshotDelay)
                let settingsTitle = AppDependencies.shared.launchRequest.settingsTab.flatMap(SettingsTab.init(rawValue:))?.title
                let visible = NSApp.windows.filter { $0.isVisible && $0.sheetParent == nil }
                let window = visible.first { $0.title == settingsTitle } ?? visible.first
                write(window?.contentView, to: url)
                if let sheet = window?.attachedSheet {
                    write(sheet.contentView, to: url.deletingPathExtension().appendingPathExtension("sheet.png"))
                }
                NSApp.terminate(nil)
            }
        }
    #endif
}

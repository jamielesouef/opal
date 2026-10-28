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
            await AppDependencies.shared.noteService.flush()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    func applicationWillResignActive(_ notification: Notification) {
        Task {
            await AppDependencies.shared.noteService.flush()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // MARK: - Snapshot

    #if DEBUG
        private func snapshotAndQuit(to url: URL) {
            Task {
                try? await Task.sleep(for: Constants.snapshotDelay)
                if let view = NSApp.windows.first(where: \.isVisible)?.contentView,
                   let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                    view.cacheDisplay(in: view.bounds, to: bitmap)
                    do {
                        try bitmap.representation(using: .png, properties: [:])?.write(to: url)
                    } catch {
                        AppLog.error("Writing the snapshot failed: \(error)")
                    }
                }
                NSApp.terminate(nil)
            }
        }
    #endif
}

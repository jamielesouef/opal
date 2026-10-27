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
    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let name = AppDependencies.shared.launchAppearance {
            NSApp.appearance = NSAppearance(named: name)
        }
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
}

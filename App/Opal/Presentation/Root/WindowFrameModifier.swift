//
//  WindowFrameModifier.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import AppKit
import OpalCore
import SwiftUI

struct WindowFrameModifier: ViewModifier {
    // MARK: - State

    @State private var window: NSWindow?

    // MARK: - Input

    let id: UUID
    let restores: Bool

    // MARK: - ViewModifier

    func body(content: Content) -> some View {
        content
            .background(WindowReader { window = $0 })
            .task(id: window) {
                if let window {
                    await track(window)
                }
            }
    }

    // MARK: - Private

    private func track(_ window: NSWindow) async {
        let windows = AppDependencies.shared.windows
        if restores, let saved = windows.savedFrame(for: id) {
            let screens = NSScreen.screens.map { WindowFrame($0.visibleFrame) }
            window.setFrame(saved.clamped(toScreens: screens).rect, display: true)
        }

        windows.setFrame(WindowFrame(window.frame), for: id)
        async let moved: Void = save(window, on: NSWindow.didMoveNotification)
        async let resized: Void = save(window, on: NSWindow.didResizeNotification)
        _ = await (moved, resized)
    }

    private func save(_ window: NSWindow, on name: Notification.Name) async {
        let windows = AppDependencies.shared.windows
        for await _ in NotificationCenter.default.notifications(named: name, object: window).map({ _ in }) {
            windows.setFrame(WindowFrame(window.frame), for: id)
        }
    }
}

extension View {
    func remembersWindowFrame(id: UUID, restores: Bool) -> some View {
        modifier(WindowFrameModifier(id: id, restores: restores))
    }
}

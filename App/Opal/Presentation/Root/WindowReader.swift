//
//  WindowReader.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import AppKit
import SwiftUI

struct WindowReader: NSViewRepresentable {
    // MARK: - Input

    let onWindow: @MainActor (NSWindow?) -> Void

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> WindowReaderView {
        let view = WindowReaderView()
        view.onWindow = onWindow
        return view
    }

    func updateNSView(_ view: WindowReaderView, context: Context) {
        view.onWindow = onWindow
    }
}

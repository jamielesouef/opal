//
//  UserDefaultsWindowListStoreTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("UserDefaultsWindowListStore", .tags(.data))
struct UserDefaultsWindowListStoreTests {
    @Test("keeps each window's state apart in a temporary suite, and a frame update keeps the panes")
    func keepsStatePerWindow() throws {
        let suite = "OpalWindowStateTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UserDefaultsWindowListStore(defaults: defaults)
        let first = UUID()
        let second = UUID()
        let frame = WindowFrame(x: 1, y: 2, width: 3, height: 4)

        store.setWindowState(WindowState(panes: [[NotePath("Soil.md")], []], focusedPane: 1, splitShare: 0.3), for: first)
        store.updateWindowState(for: first) { $0.frame = frame }

        let reopened = UserDefaultsWindowListStore(defaults: defaults).windowState(for: first)
        #expect(reopened == WindowState(panes: [[NotePath("Soil.md")], []], focusedPane: 1, splitShare: 0.3, frame: frame))
        #expect(store.windowState(for: second) == nil)

        store.setWindowState(nil, for: first)
        #expect(store.windowState(for: first) == nil)
    }
}

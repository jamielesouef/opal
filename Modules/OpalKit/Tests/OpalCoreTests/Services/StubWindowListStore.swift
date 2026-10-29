//
//  StubWindowListStore.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
@testable import OpalCore

final class StubWindowListStore: WindowListStoring, @unchecked Sendable {
    // MARK: - Stored

    private var ids: [UUID] = []
    private var states: [UUID: WindowState] = [:]

    // MARK: - WindowListStoring

    func windowIDs() -> [UUID] {
        ids
    }

    func setWindowIDs(_ ids: [UUID]) {
        self.ids = ids
    }

    func windowState(for id: UUID) -> WindowState? {
        states[id]
    }

    func setWindowState(_ state: WindowState?, for id: UUID) {
        states[id] = state
    }
}

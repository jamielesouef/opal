//
//  WindowListStoring.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

public protocol WindowListStoring: Sendable {
    func windowIDs() -> [UUID]
    func setWindowIDs(_ ids: [UUID])
    func windowState(for id: UUID) -> WindowState?
    func setWindowState(_ state: WindowState?, for id: UUID)
}

extension WindowListStoring {
    public func updateWindowState(for id: UUID, _ change: (inout WindowState) -> Void) {
        var state = windowState(for: id) ?? WindowState()
        change(&state)
        setWindowState(state, for: id)
    }
}

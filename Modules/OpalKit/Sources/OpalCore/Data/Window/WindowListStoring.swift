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
}

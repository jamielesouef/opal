//
//  OpenVaultDecision.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

public enum OpenVaultDecision: Hashable, Sendable {
    case bringToFront(UUID)
    case openHere
    case openInNewWindow
}

//
//  Clocking.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public protocol Clocking: Sendable {
    var now: Date { get }
    var timeZone: TimeZone { get }
}

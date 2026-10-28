//
//  FixedClock.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
@testable import OpalCore

struct FixedClock: Clocking {
    // MARK: - Clocking

    let now: Date
    let timeZone: TimeZone
}

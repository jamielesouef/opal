//
//  SystemClock.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import OpalCore

struct SystemClock: Clocking {
    // MARK: - Clocking

    var now: Date {
        .now
    }

    var timeZone: TimeZone {
        .current
    }
}

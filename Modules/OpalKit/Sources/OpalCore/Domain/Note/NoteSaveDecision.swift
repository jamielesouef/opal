//
//  NoteSaveDecision.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum NoteSaveDecision: Hashable, Sendable {
    case unchanged
    case write
    case recreate
    case adoptDisk(String)
    case conflict(diskText: String)
}

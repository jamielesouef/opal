//
//  IndexError.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum IndexError: Error, Hashable, Sendable {
    case cannotOpen
    case readFailed
    case writeFailed
}

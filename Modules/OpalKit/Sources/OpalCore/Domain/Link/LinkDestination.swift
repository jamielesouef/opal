//
//  LinkDestination.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum LinkDestination: Hashable, Sendable {
    case note(NotePath, line: Int?)
    case attachment(NotePath)
    case create(NotePath)
    case nowhere
}

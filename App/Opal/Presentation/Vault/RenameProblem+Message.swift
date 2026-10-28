//
//  RenameProblem+Message.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore

extension RenameProblem {
    // MARK: - Message

    var message: String {
        switch self {
        case .empty:
            String(localized: "A name can't be empty.")
        case let .invalidCharacter(character):
            String(localized: "A name can't contain “\(String(character))”.")
        case .startsWithDot:
            String(localized: "A name can't start with a full stop; the file would be hidden.")
        case let .taken(path):
            String(localized: "“\(path.fileName)” already exists in this Folder.")
        case .unchanged:
            ""
        }
    }
}

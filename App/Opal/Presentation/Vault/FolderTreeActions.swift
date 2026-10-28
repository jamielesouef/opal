//
//  FolderTreeActions.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore

struct FolderTreeActions {
    // MARK: - Stored

    var reveal: (NotePath) -> Void = { _ in }
    var openInDefaultApp: (NotePath) -> Void = { _ in }
    var rename: (NotePath, String) -> Void = { _, _ in }
    var move: (NotePath, NotePath) -> Void = { _, _ in }
    var chooseFolder: (NotePath) -> Void = { _ in }
    var duplicate: (NotePath) -> Void = { _ in }
    var delete: (NotePath) -> Void = { _ in }
}

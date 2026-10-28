//
//  MoveRequest.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore

struct MoveRequest: Identifiable {
    // MARK: - Stored

    let path: NotePath

    // MARK: - Identifiable

    var id: NotePath {
        path
    }
}

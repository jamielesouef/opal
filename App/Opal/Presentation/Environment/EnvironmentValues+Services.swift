//
//  EnvironmentValues+Services.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import SwiftUI

private let defaultVaultService = MainActor.assumeIsolated {
    AppDependencies.shared.vaultService
}

private let defaultNoteService = MainActor.assumeIsolated {
    AppDependencies.shared.noteService
}

extension EnvironmentValues {
    @Entry var vaultService: VaultService = defaultVaultService
    @Entry var noteService: NoteService = defaultNoteService
}

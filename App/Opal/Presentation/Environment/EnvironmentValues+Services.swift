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

private let defaultLinkService = MainActor.assumeIsolated {
    AppDependencies.shared.linkService
}

private let defaultNavigationService = MainActor.assumeIsolated {
    AppDependencies.shared.navigationService
}

private let defaultQuickSwitcherService = MainActor.assumeIsolated {
    AppDependencies.shared.quickSwitcherService
}

private let defaultIndexService = MainActor.assumeIsolated {
    AppDependencies.shared.indexService
}

extension EnvironmentValues {
    @Entry var vaultService: VaultService = defaultVaultService
    @Entry var noteService: NoteService = defaultNoteService
    @Entry var linkService: LinkService = defaultLinkService
    @Entry var indexService: IndexService = defaultIndexService
    @Entry var navigationService: NavigationService = defaultNavigationService
    @Entry var quickSwitcherService: QuickSwitcherService = defaultQuickSwitcherService
    @Entry var launchTypeText: String?
}

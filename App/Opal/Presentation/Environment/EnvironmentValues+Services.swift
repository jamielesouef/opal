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

private let defaultSearchService = MainActor.assumeIsolated {
    AppDependencies.shared.searchService
}

private let defaultMentionService = MainActor.assumeIsolated {
    AppDependencies.shared.mentionService
}

private let defaultDailyNoteService = MainActor.assumeIsolated {
    AppDependencies.shared.dailyNoteService
}

private let defaultTemplateService = MainActor.assumeIsolated {
    AppDependencies.shared.templateService
}

private let defaultRenameService = MainActor.assumeIsolated {
    AppDependencies.shared.renameService
}

extension EnvironmentValues {
    @Entry var vaultService: VaultService = defaultVaultService
    @Entry var noteService: NoteService = defaultNoteService
    @Entry var linkService: LinkService = defaultLinkService
    @Entry var indexService: IndexService = defaultIndexService
    @Entry var searchService: SearchService = defaultSearchService
    @Entry var mentionService: MentionService = defaultMentionService
    @Entry var dailyNoteService: DailyNoteService = defaultDailyNoteService
    @Entry var templateService: TemplateService = defaultTemplateService
    @Entry var renameService: RenameService = defaultRenameService
    @Entry var navigationService: NavigationService = defaultNavigationService
    @Entry var quickSwitcherService: QuickSwitcherService = defaultQuickSwitcherService
    @Entry var launchRequest = LaunchRequest()
}

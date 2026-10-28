//
//  EnvironmentValues+Services.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import SwiftUI

private let defaultVaultService = MainActor.assumeIsolated {
    AppDependencies.shared.services.vault
}

private let defaultNoteService = MainActor.assumeIsolated {
    AppDependencies.shared.services.notes
}

private let defaultLinkService = MainActor.assumeIsolated {
    AppDependencies.shared.services.links
}

private let defaultNavigationService = MainActor.assumeIsolated {
    AppDependencies.shared.services.navigation
}

private let defaultQuickSwitcherService = MainActor.assumeIsolated {
    AppDependencies.shared.services.switcher
}

private let defaultIndexService = MainActor.assumeIsolated {
    AppDependencies.shared.services.index
}

private let defaultSearchService = MainActor.assumeIsolated {
    AppDependencies.shared.services.search
}

private let defaultMentionService = MainActor.assumeIsolated {
    AppDependencies.shared.services.mentions
}

private let defaultDailyNoteService = MainActor.assumeIsolated {
    AppDependencies.shared.services.dailyNotes
}

private let defaultTemplateService = MainActor.assumeIsolated {
    AppDependencies.shared.services.templates
}

private let defaultRenameService = MainActor.assumeIsolated {
    AppDependencies.shared.services.renames
}

private let defaultSettingsService = MainActor.assumeIsolated {
    AppDependencies.shared.services.settings
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
    @Entry var settingsService: SettingsService = defaultSettingsService
    @Entry var quickSwitcherService: QuickSwitcherService = defaultQuickSwitcherService
    @Entry var launchRequest = LaunchRequest()
}

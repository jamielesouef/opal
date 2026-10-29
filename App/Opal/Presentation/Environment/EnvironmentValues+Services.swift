//
//  EnvironmentValues+Services.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import SwiftUI

private let defaultVaultService = MainActor.assumeIsolated {
    AppDependencies.shared.placeholder.vault
}

private let defaultNoteService = MainActor.assumeIsolated {
    AppDependencies.shared.placeholder.notes
}

private let defaultLinkService = MainActor.assumeIsolated {
    AppDependencies.shared.placeholder.links
}

private let defaultNavigationService = MainActor.assumeIsolated {
    AppDependencies.shared.placeholder.navigation
}

private let defaultQuickSwitcherService = MainActor.assumeIsolated {
    AppDependencies.shared.placeholder.switcher
}

private let defaultIndexService = MainActor.assumeIsolated {
    AppDependencies.shared.placeholder.index
}

private let defaultSearchService = MainActor.assumeIsolated {
    AppDependencies.shared.placeholder.search
}

private let defaultMentionService = MainActor.assumeIsolated {
    AppDependencies.shared.placeholder.mentions
}

private let defaultDailyNoteService = MainActor.assumeIsolated {
    AppDependencies.shared.placeholder.dailyNotes
}

private let defaultTemplateService = MainActor.assumeIsolated {
    AppDependencies.shared.placeholder.templates
}

private let defaultRenameService = MainActor.assumeIsolated {
    AppDependencies.shared.placeholder.renames
}

private let defaultSettingsService = MainActor.assumeIsolated {
    AppDependencies.shared.settings
}

private let defaultServiceGraph = MainActor.assumeIsolated {
    AppDependencies.shared.placeholder
}

extension EnvironmentValues {
    @Entry var windowID: UUID?
    @Entry var serviceGraph: ServiceGraph = defaultServiceGraph
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

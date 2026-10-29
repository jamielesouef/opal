//
//  PreviewGraph.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

#if DEBUG
    import Foundation
    import OpalCore

    @MainActor
    enum PreviewGraph {
        // MARK: - Fixtures

        static let gardenRoot = URL(filePath: "/Preview/Garden")
        static let previewDefaultsSuite = "com.jamielesouef.Opal.previews"

        static let gardenFiles: [String: String] = [
            "Welcome.md": "---\naliases:\n  - Start Here\n---\n# Welcome\n\nStart with [[Gardening Basics]].\n",
            "Soil.md": "# Soil\n\nSoil is a mix of sand, silt, clay and organic matter.\n\nSee [[Areas/Health]] and [[Compost]].\n",
            "Areas/Health.md": "# Health\n\nWalk every day.\n",
            "Attachments/seedlings.png": ""
        ]

        // MARK: - Graph

        static func makeGraph(openingGarden: Bool) -> ServiceGraph {
            let store = MockVaultFileStore(rootURL: gardenRoot, files: gardenFiles, folders: ["Areas", "Attachments"])
            let vaultService = VaultService(
                access: MockVaultAccess(),
                locations: MockVaultLocationStore(),
                launchVaultURL: openingGarden ? gardenRoot : nil
            ) { _ in store }
            let defaults = UserDefaults(suiteName: previewDefaultsSuite) ?? .standard
            let indexBaseURL = FileManager().temporaryDirectory.appending(component: "OpalPreviewIndexes")
            return ServiceGraph(
                vault: vaultService,
                makeIndex: { root throws(IndexError) in
                    try GRDBIndexStore(folderURL: IndexLocation.folder(forVaultAt: root, in: indexBaseURL))
                },
                recents: UserDefaultsRecentNotesStore(defaults: defaults),
                windowID: UUID(),
                windows: UserDefaultsWindowListStore(defaults: defaults),
                settings: SettingsService(store: UserDefaultsSettingsStore(defaults: defaults), clock: SystemClock()),
                clock: SystemClock()
            )
        }
    }
#endif

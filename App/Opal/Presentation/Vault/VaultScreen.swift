//
//  VaultScreen.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct VaultScreen: View {
    // MARK: - Environment

    @Environment(\.vaultService) private var vaultService
    @Environment(\.noteService) private var notes
    @Environment(\.linkService) private var links
    @Environment(\.navigationService) private var navigation

    // MARK: - State

    @State private var selection: NotePath?
    @State private var expandedFolders: Set<NotePath> = []

    // MARK: - Input

    let vault: Vault

    // MARK: - View

    var body: some View {
        @Bindable var navigation = navigation
        NavigationSplitView {
            FolderTreeView(
                selection: $selection,
                expandedFolders: $expandedFolders,
                vaultName: vault.name,
                tree: vaultService.tree
            ) { path in
                VaultActions.reveal(path, vault: vaultService)
            } onOpenInDefaultApp: { path in
                VaultActions.openInDefaultApp(path, vault: vaultService)
            }
            .navigationSplitViewColumnWidth(min: EditorMetrics.sidebarMinWidth, ideal: EditorMetrics.sidebarIdealWidth)
        } detail: {
            detail
                .inspector(isPresented: $navigation.isInspectorShown) {
                    InspectorView()
                        .inspectorColumnWidth(
                            min: EditorMetrics.inspectorMinWidth,
                            ideal: EditorMetrics.inspectorIdealWidth,
                            max: EditorMetrics.inspectorMaxWidth
                        )
                }
        }
        .navigationTitle(WindowTitleUseCase.title(vaultName: vault.name, openNote: notes.path))
        .navigationSubtitle(WindowTitleUseCase.subtitle(vaultName: vault.name, openNote: notes.path))
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    Task { await navigation.goBack() }
                } label: {
                    Label(String(localized: "Back"), systemImage: "chevron.backward")
                }
                .help(String(localized: "Go back (⌘[)"))
                .disabled(navigation.history.canGoBack == false)

                Button {
                    Task { await navigation.goForward() }
                } label: {
                    Label(String(localized: "Forward"), systemImage: "chevron.forward")
                }
                .help(String(localized: "Go forward (⌘])"))
                .disabled(navigation.history.canGoForward == false)
            }

            ToolbarItem(placement: .status) {
                SaveStatusView(status: notes.saveStatus, hasNote: notes.path != nil)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    navigation.isInspectorShown.toggle()
                } label: {
                    Label(String(localized: "Inspector"), systemImage: "sidebar.trailing")
                }
                .help(String(localized: "Show or hide Backlinks and the outline (⌥⌘0)"))
            }
        }
        .onChange(of: selection) { _, newSelection in
            guard let newSelection, vaultService.kind(of: newSelection) == .note else {
                return
            }

            Task { await navigation.open(newSelection) }
        }
        .sheet(isPresented: $navigation.isQuickSwitcherShown) {
            QuickSwitcherView()
        }
        .task(id: vaultService.entries) {
            await links.sync()
        }
        .onChange(of: notes.path) { _, openPath in
            guard let openPath else {
                return
            }

            expandedFolders.formUnion(openPath.ancestors)
            selection = openPath
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        switch DetailContentUseCase.content(selection: selection, kind: selection.flatMap(vaultService.kind(of:))) {
        case .note:
            NoteScreen()
        case let .attachment(path):
            AttachmentView(name: path.fileName) {
                VaultActions.openInDefaultApp(path, vault: vaultService)
            }
        }
    }
}

#if DEBUG
    #Preview {
        let graph = PreviewGraph.makeGraph(openingGarden: true)
        VaultScreen(vault: Vault(rootURL: PreviewGraph.gardenRoot))
            .environment(\.vaultService, graph.vaultService)
            .environment(\.noteService, graph.noteService)
            .environment(\.linkService, graph.linkService)
            .environment(\.navigationService, graph.navigationService)
            .environment(\.quickSwitcherService, graph.quickSwitcherService)
            .task { await graph.vaultService.start() }
    }
#endif

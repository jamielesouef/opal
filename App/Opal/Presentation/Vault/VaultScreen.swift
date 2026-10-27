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
    @Environment(\.indexService) private var index
    @Environment(\.searchService) private var search
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
            sidebar
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    IndexStatusView(state: index.loadState)
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
        .onChange(of: index.revision) {
            Task { await search.search() }
        }
        .task(id: vaultService.entries) {
            await index.sync()
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

    // MARK: - Sidebar

    private var sidebar: some View {
        @Bindable var navigation = navigation
        return VStack(spacing: 0) {
            Picker(String(localized: "Sidebar"), selection: $navigation.sidebarPane) {
                ForEach(SidebarPane.allCases) { pane in
                    Label(pane.title, systemImage: pane.systemImage)
                        .labelStyle(.iconOnly)
                        .help(pane.title)
                        .tag(pane)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, AppSpacing.small)
            .padding(.bottom, AppSpacing.xsmall)

            switch navigation.sidebarPane {
            case .files:
                folderTree
            case .search:
                SearchView()
            case .tags:
                TagsView(tags: links.map.tags) { tag in
                    search.show(query: TagTreeUseCase.searchQuery(for: tag))
                }
            }
        }
    }

    private var folderTree: some View {
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
            .environment(\.indexService, graph.indexService)
            .environment(\.searchService, graph.searchService)
            .environment(\.navigationService, graph.navigationService)
            .environment(\.quickSwitcherService, graph.quickSwitcherService)
            .task { await graph.vaultService.start() }
    }
#endif

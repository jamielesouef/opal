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
    @Environment(\.searchService) private var search
    @Environment(\.navigationService) private var navigation
    @Environment(\.dailyNoteService) private var dailyNotes
    @Environment(\.templateService) private var templates

    // MARK: - State

    @State private var selection: NotePath?
    @State private var expandedFolders: Set<NotePath> = []

    // MARK: - Input

    let vault: Vault

    // MARK: - View

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var templates = templates
        NavigationSplitView {
            sidebar
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    IndexStatusItem()
                }
                .navigationSplitViewColumnWidth(min: EditorMetrics.sidebarMinWidth, ideal: EditorMetrics.sidebarIdealWidth)
        } detail: {
            detail
                .safeAreaInset(edge: .top, spacing: 0) {
                    if notes.path != nil || navigation.tabs.tabs.count > 1 {
                        VStack(spacing: 0) {
                            TabBarView()
                            Divider()
                        }
                    }
                }
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

            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await dailyNotes.openToday() }
                } label: {
                    Label(String(localized: "Today's Daily Note"), systemImage: "calendar")
                }
                .help(String(localized: "Open today's Daily Note (⌥⌘D)"))
            }

            ToolbarItem(placement: .status) {
                SaveStatusItem()
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    navigation.isReadingView.toggle()
                } label: {
                    Label(
                        navigation.isReadingView ? String(localized: "Editor") : String(localized: "Reading View"),
                        systemImage: navigation.isReadingView ? "pencil" : "book"
                    )
                }
                .help(navigation.isReadingView ? String(localized: "Edit the Note (⌘E)") : String(localized: "Read the Note without its Markdown (⌘E)"))
                .disabled(notes.path == nil)
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
        .sheet(isPresented: $templates.isPickerShown) {
            TemplatePickerView()
        }
        .sheet(isPresented: $navigation.isCommandPaletteShown) {
            CommandPaletteView()
        }
        .background(VaultSync())
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
        FolderTreePane(selection: $selection, expandedFolders: $expandedFolders, vaultName: vault.name)
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
            .environment(\.mentionService, graph.mentionService)
            .environment(\.dailyNoteService, graph.dailyNoteService)
            .environment(\.templateService, graph.templateService)
            .environment(\.renameService, graph.renameService)
            .environment(\.navigationService, graph.navigationService)
            .environment(\.quickSwitcherService, graph.quickSwitcherService)
            .task { await graph.vaultService.start() }
    }
#endif

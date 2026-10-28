//
//  FolderTreeRow.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import SwiftUI

struct FolderTreeRow: View {
    // MARK: - State

    @State private var isExpanded = false
    @State private var draftName = ""
    @FocusState private var isNameFocused: Bool

    // MARK: - Binding

    @Binding var expandedFolders: Set<NotePath>
    @Binding var renaming: NotePath?

    // MARK: - Input

    let node: VaultTreeNode
    var actions = FolderTreeActions()

    // MARK: - Init

    init(
        node: VaultTreeNode,
        expandedFolders: Binding<Set<NotePath>>,
        renaming: Binding<NotePath?> = .constant(nil),
        actions: FolderTreeActions = FolderTreeActions()
    ) {
        self.node = node
        _expandedFolders = expandedFolders
        _renaming = renaming
        self.actions = actions
    }

    // MARK: - View

    var body: some View {
        if let children = node.children {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(children) { child in
                    FolderTreeRow(node: child, expandedFolders: $expandedFolders, renaming: $renaming, actions: actions)
                }
            } label: {
                label
            }
            .onAppear {
                isExpanded = expandedFolders.contains(node.path)
            }
            .onChange(of: expandedFolders.contains(node.path)) { _, expanded in
                isExpanded = expanded
            }
            .onChange(of: isExpanded) { _, expanded in
                if expanded {
                    expandedFolders.insert(node.path)
                } else {
                    expandedFolders.remove(node.path)
                }
            }
        } else {
            label
        }
    }

    // MARK: - Label

    @ViewBuilder
    private var label: some View {
        if renaming == node.path {
            Label {
                TextField(String(localized: "Name"), text: $draftName)
                    .textFieldStyle(.plain)
                    .focused($isNameFocused)
                    .onSubmit {
                        renaming = nil
                        actions.rename(node.path, draftName)
                    }
                    .onExitCommand {
                        renaming = nil
                    }
                    .onAppear {
                        draftName = node.displayName
                        isNameFocused = true
                    }
            } icon: {
                Image(systemName: symbol)
            }
            .tag(node.path)
        } else {
            Label(node.displayName, systemImage: symbol)
                .lineLimit(1)
                .tag(node.path)
                .draggable(node.path.rawValue)
                .dropDestination(for: String.self) { items, _ in
                    guard node.kind == .folder else {
                        return false
                    }
                    for item in items {
                        actions.move(NotePath(item), node.path)
                    }
                    return items.isEmpty == false
                }
                .contextMenu {
                    Button(String(localized: "Rename…")) {
                        renaming = node.path
                    }

                    Button(String(localized: "Move to…")) {
                        actions.chooseFolder(node.path)
                    }

                    if node.kind == .note {
                        Button(String(localized: "Duplicate")) {
                            actions.duplicate(node.path)
                        }
                    }

                    Divider()

                    Button(String(localized: "Reveal in Finder")) {
                        actions.reveal(node.path)
                    }

                    if node.kind == .attachment {
                        Button(String(localized: "Open in Default App")) {
                            actions.openInDefaultApp(node.path)
                        }
                    }
                }
        }
    }

    // MARK: - Helpers

    private var symbol: String {
        switch node.kind {
        case .folder:
            "folder"
        case .note:
            "text.document"
        case .attachment:
            "paperclip"
        }
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var expanded: Set<NotePath> = [NotePath("Areas")]
        List {
            FolderTreeRow(
                node: VaultTreeNode(
                    path: NotePath("Areas"),
                    kind: .folder,
                    children: [VaultTreeNode(path: NotePath("Areas/Health.md"), kind: .note, children: nil)]
                ),
                expandedFolders: $expanded
            )
            FolderTreeRow(node: VaultTreeNode(path: NotePath("seedlings.png"), kind: .attachment, children: nil), expandedFolders: $expanded)
        }
        .frame(width: 260, height: 200)
    }
#endif

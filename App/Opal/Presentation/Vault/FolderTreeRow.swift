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

    // MARK: - Binding

    @Binding var expandedFolders: Set<NotePath>

    // MARK: - Input

    let node: VaultTreeNode
    var onReveal: (NotePath) -> Void = { _ in }
    var onOpenInDefaultApp: (NotePath) -> Void = { _ in }

    // MARK: - Init

    init(
        node: VaultTreeNode,
        expandedFolders: Binding<Set<NotePath>>,
        onReveal: @escaping (NotePath) -> Void = { _ in },
        onOpenInDefaultApp: @escaping (NotePath) -> Void = { _ in }
    ) {
        self.node = node
        _expandedFolders = expandedFolders
        self.onReveal = onReveal
        self.onOpenInDefaultApp = onOpenInDefaultApp
    }

    // MARK: - View

    var body: some View {
        if let children = node.children {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(children) { child in
                    FolderTreeRow(
                        node: child,
                        expandedFolders: $expandedFolders,
                        onReveal: onReveal,
                        onOpenInDefaultApp: onOpenInDefaultApp
                    )
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

    private var label: some View {
        Label(node.displayName, systemImage: symbol)
            .lineLimit(1)
            .tag(node.path)
            .contextMenu {
                Button(String(localized: "Reveal in Finder")) {
                    onReveal(node.path)
                }

                if node.kind == .attachment {
                    Button(String(localized: "Open in Default App")) {
                        onOpenInDefaultApp(node.path)
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

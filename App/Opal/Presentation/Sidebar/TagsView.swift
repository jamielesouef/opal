//
//  TagsView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import SwiftUI

struct TagsView: View {
    // MARK: - Input

    let tags: [TagNode]
    var onSelect: (TagNode) -> Void = { _ in }

    // MARK: - View

    var body: some View {
        if tags.isEmpty {
            ContentUnavailableView(
                String(localized: "No Tags"),
                systemImage: "number",
                description: Text(String(localized: "Write #tag in a Note, or add a tags Property."))
            )
        } else {
            List {
                OutlineGroup(tags, children: \.children) { tag in
                    Button {
                        onSelect(tag)
                    } label: {
                        HStack {
                            Label(tag.name, systemImage: "number")
                                .lineLimit(1)
                            Spacer()
                            Text(tag.noteCount, format: .number)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .help(String(localized: "Search for #\(tag.fullName)"))
                }
            }
            .listStyle(.sidebar)
        }
    }
}

#if DEBUG
    #Preview {
        TagsView(tags: TagTreeUseCase.tree(from: [
            NotePath("A.md"): ["garden", "garden/harvest", "garden/mulch"],
            NotePath("B.md"): ["project/opal", "reading"]
        ]))
        .frame(width: 260, height: 300)
    }
#endif

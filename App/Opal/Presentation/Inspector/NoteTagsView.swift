//
//  NoteTagsView.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import SwiftUI

struct NoteTagsView: View {
    // MARK: - Input

    let tags: [String]
    var onSelect: (String) -> Void = { _ in }

    // MARK: - View

    var body: some View {
        if tags.isEmpty {
            ContentUnavailableView(
                String(localized: "No Tags"),
                systemImage: "tag",
                description: Text(String(localized: "Write #tag in the Note, or add a tags Property."))
            )
        } else {
            List(tags, id: \.self) { tag in
                Button {
                    onSelect(tag)
                } label: {
                    Label("#\(tag)", systemImage: "tag")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .help(String(localized: "Search for Notes with #\(tag)"))
            }
            .listStyle(.sidebar)
        }
    }
}

#if DEBUG
    #Preview {
        NoteTagsView(tags: ["garden", "garden/harvest", "meta"])
            .frame(width: 280, height: 300)
    }
#endif

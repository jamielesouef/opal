//
//  OutlineView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct OutlineView: View {
    // MARK: - Input

    let headings: [Heading]
    var onSelect: (Heading) -> Void = { _ in }

    // MARK: - View

    var body: some View {
        if headings.isEmpty {
            ContentUnavailableView(
                String(localized: "No Headings"),
                systemImage: "list.bullet.indent",
                description: Text(String(localized: "Start a line with # to add a Heading."))
            )
        } else {
            let topLevel = headings.map(\.level).min() ?? 1
            List(headings, id: \.self) { heading in
                Button {
                    onSelect(heading)
                } label: {
                    Text(heading.text)
                        .fontWeight(heading.level == topLevel ? .semibold : .regular)
                        .lineLimit(1)
                        .padding(.leading, CGFloat(heading.level - topLevel) * AppSpacing.regular)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.sidebar)
        }
    }
}

#if DEBUG
    #Preview {
        OutlineView(headings: [
            Heading(level: 1, text: "Opal Roadmap", line: 6),
            Heading(level: 2, text: "Milestone 1", line: 8),
            Heading(level: 2, text: "Milestone 2", line: 12),
            Heading(level: 3, text: "Links", line: 14)
        ])
        .frame(width: 280, height: 300)
    }
#endif

//
//  LinkSuggestionList.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct LinkSuggestionList: View {
    // MARK: - Input

    let suggestions: [LinkSuggestion]
    let selectedIndex: Int
    var onPick: (Int) -> Void = { _ in }

    // MARK: - View

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                        LinkSuggestionRow(suggestion: suggestion, isSelected: index == selectedIndex)
                            .id(index)
                            .onTapGesture {
                                onPick(index)
                            }
                    }
                }
                .padding(AppSpacing.xsmall)
            }
            .onChange(of: selectedIndex) { _, index in
                proxy.scrollTo(index)
            }
        }
        .frame(width: EditorMetrics.suggestionWidth)
        .background(.regularMaterial, in: .rect(cornerRadius: 8))
    }
}

#if DEBUG
    #Preview {
        LinkSuggestionList(
            suggestions: [
                .note(NotePath("Soil.md"), alias: "Dirt"),
                .note(NotePath("Reading/The Soil Book.md"), alias: nil),
                .unresolved("Ideas That Do Not Exist Yet")
            ],
            selectedIndex: 0
        )
        .frame(height: 180)
        .padding()
    }
#endif

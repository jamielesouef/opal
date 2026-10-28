//
//  ReadingView.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct ReadingView: View {
    // MARK: - Input

    let source: NotePath
    let blocks: [ReadingBlock]
    let startLine: Int
    var onTopLine: (Int) -> Void = { _ in }
    var onFollowLink: (OpalCore.Link) -> Void = { _ in }
    var onToggleCheckbox: (Int) -> Void = { _ in }

    // MARK: - State

    @State private var position: ReadingBlockID?

    // MARK: - View

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.regular) {
                ForEach(blocks) { block in
                    ReadingBlockView(block: block, chain: [source], onToggleCheckbox: onToggleCheckbox)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .scrollTargetLayout()
            .textSelection(.enabled)
            .font(.system(size: EditorMetrics.fontSize))
            .padding(EditorMetrics.textInset)
        }
        .scrollPosition(id: $position, anchor: .top)
        .tint(.accentColor)
        .background(Color(nsColor: .textBackgroundColor))
        .environment(\.openURL, OpenURLAction { url in
            guard let offset = ReadingText.linkOffset(of: url), let link = links[offset] else {
                return .systemAction
            }

            onFollowLink(link)
            return .handled
        })
        .onAppear(perform: scrollToStart)
        .onChange(of: blocks) {
            if position == nil {
                scrollToStart()
            }
        }
        .onChange(of: position) { _, id in
            if let id {
                onTopLine(id.line)
            }
        }
    }

    // MARK: - Scroll

    private func scrollToStart() {
        position = blocks.last { $0.line <= startLine && $0.isHeading }?.id ?? blocks.last { $0.line <= startLine }?.id
    }

    // MARK: - Links

    private var links: [Int: OpalCore.Link] {
        var result: [Int: OpalCore.Link] = [:]
        for block in blocks {
            for inline in block.inlines {
                if let link = inline.link {
                    result[link.span.location] = link
                }
            }
        }
        return result
    }
}

//
//  EmbedView.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct EmbedView: View {
    // MARK: - Constants

    private enum Constants {
        static let maximumDepth = 4
        static let cornerRadius: CGFloat = 6
        static let pdfHeight: CGFloat = 480
    }

    // MARK: - Environment

    @Environment(\.vaultService) private var vault
    @Environment(\.linkService) private var links
    @Environment(\.indexService) private var index
    @Environment(\.navigationService) private var navigation

    // MARK: - Input

    let link: OpalCore.Link
    let chain: [NotePath]

    // MARK: - State

    @State private var content: EmbedContent?
    @State private var image: NSImage?

    // MARK: - View

    var body: some View {
        Group {
            switch content {
            case nil:
                ProgressView()
                    .controlSize(.small)
            case let .note(path, title, blocks):
                note(path: path, title: title, blocks: blocks)
            case let .image(path, width):
                imageView(path: path, width: width)
            case let .pdf(path):
                if let url = vault.url(for: path) {
                    PDFEmbedView(url: url)
                        .frame(height: Constants.pdfHeight)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
                }
            case let .file(path):
                Button(path.name, systemImage: "doc") {
                    VaultActions.openInDefaultApp(path, vault: vault)
                }
                .buttonStyle(.link)
            case let .unresolved(name):
                HStack {
                    Text(String(localized: "“\(name)” is not in this Vault."))
                        .foregroundStyle(.secondary)
                    Button(String(localized: "Create Note")) {
                        follow()
                    }
                }
            case let .recursive(path):
                Text(String(localized: "“\(path.name)” is already shown above, so Opal does not embed it again."))
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: EmbedKey(location: link.span.location, target: link.target, revision: index.revision, mapRevision: links.mapRevision)) {
            guard let source = chain.last, chain.count < Constants.maximumDepth else {
                content = .recursive(NotePath(link.target))
                return
            }
            content = await links.embed(link, from: source, chain: chain)
        }
    }

    // MARK: - Parts

    private func note(path: NotePath, title: String, blocks: [ReadingBlock]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Button(title, systemImage: "text.document") {
                follow()
            }
            .buttonStyle(.link)
            .font(.callout)
            .help(String(localized: "Open \(path.name)"))

            ForEach(blocks) { block in
                ReadingBlockView(block: block, chain: chain + [path])
            }
        }
        .padding(AppSpacing.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: Constants.cornerRadius).stroke(.separator))
    }

    @ViewBuilder
    private func imageView(path: NotePath, width: Int?) -> some View {
        if let image {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: width.map { CGFloat($0) } ?? image.size.width, alignment: .leading)
                .accessibilityLabel(link.displayText ?? path.name)
        } else {
            Text(path.name)
                .foregroundStyle(.secondary)
                .task(id: path) {
                    guard let url = vault.url(for: path), let data = await Self.read(url) else {
                        return
                    }
                    image = NSImage(data: data)
                }
        }
    }

    @concurrent
    private nonisolated static func read(_ url: URL) async -> Data? {
        try? Data(contentsOf: url)
    }

    // MARK: - Intent

    private func follow() {
        guard let source = chain.last else {
            return
        }

        Task { await VaultActions.follow(link, from: source, vault: vault, navigation: navigation) }
    }
}

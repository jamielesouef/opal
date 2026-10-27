//
//  IndexStatusView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct IndexStatusView: View {
    // MARK: - Input

    let state: IndexService.LoadState

    // MARK: - View

    var body: some View {
        switch state {
        case .closed,
             .ready:
            EmptyView()
        case let .indexing(done, total):
            VStack(alignment: .leading, spacing: AppSpacing.xsmall) {
                ProgressView(value: Double(done), total: Double(max(total, 1)))
                    .controlSize(.small)
                Text(String(localized: "Indexing \(done) of \(total) Notes…"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(AppSpacing.regular)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)
            .overlay(alignment: .top) {
                Divider()
            }
        case .failed:
            Label(String(localized: "Search is unavailable. Notes still open and save."), systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(AppSpacing.regular)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.bar)
                .help(String(localized: "Opal could not open its Index. It will try again next time the Vault opens."))
        }
    }
}

#if DEBUG
    #Preview("Indexing") {
        IndexStatusView(state: .indexing(done: 120, total: 2000))
            .frame(width: 260)
    }

    #Preview("Failed") {
        IndexStatusView(state: .failed(.cannotOpen))
            .frame(width: 260)
    }
#endif

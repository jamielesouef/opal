//
//  RecentVaultRow.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct RecentVaultRow: View {
    // MARK: - Input

    let vault: RecentVault
    var onChoose: () -> Void = {}
    var onRemove: () -> Void = {}

    // MARK: - State

    @State private var isHovering = false

    // MARK: - View

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Button(action: onChoose) {
                VStack(alignment: .leading, spacing: AppSpacing.tiny) {
                    Text(vault.name)
                        .lineLimit(1)
                    Text(vault.isMissing ? String(localized: "Folder not found") : vault.parentPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(vault.isMissing)
            .accessibilityHint(vault.isMissing ? "" : String(localized: "Opens this Vault"))

            if vault.isMissing {
                Button(String(localized: "Remove"), action: onRemove)
                    .controlSize(.small)
                    .accessibilityLabel(String(localized: "Remove \(vault.name) from the list"))
            }
        }
        .opacity(vault.isMissing ? AppOpacity.disabled : 1)
        .padding(.horizontal, AppSpacing.small)
        .frame(height: EditorMetrics.welcomeRecentRowHeight)
        .background {
            if isHovering, vault.isMissing == false {
                RoundedRectangle(cornerRadius: AppRadius.row, style: .continuous)
                    .fill(.quaternary)
            }
        }
        .onHover { isHovering = $0 }
        .contextMenu {
            Button(String(localized: "Remove from List"), action: onRemove)
        }
    }
}

#if DEBUG
    #Preview("Recent Vaults") {
        VStack {
            RecentVaultRow(vault: RecentVault(record: RecentVaultRecord(bookmark: Data(), path: "/Vaults/Garden"), folderURL: URL(filePath: "/Vaults/Garden"), isMissing: false))
            RecentVaultRow(vault: RecentVault(record: RecentVaultRecord(bookmark: Data(), path: "/Vaults/Old"), folderURL: URL(filePath: "/Vaults/Old"), isMissing: true))
        }
        .frame(width: EditorMetrics.welcomeWidth)
        .padding(AppSpacing.large)
    }
#endif

//
//  WelcomeView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct WelcomeView: View {
    // MARK: - Input

    let message: String?
    var recents: [RecentVault] = []
    var onOpen: () -> Void = {}
    var onCreate: () -> Void = {}
    var onChoose: (RecentVault) -> Void = { _ in }
    var onRemove: (RecentVault) -> Void = { _ in }

    // MARK: - View

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: EditorMetrics.welcomeIconSize, height: EditorMetrics.welcomeIconSize)
                .accessibilityHidden(true)

            VStack(spacing: AppSpacing.small) {
                Text(String(localized: "Welcome to Opal"))
                    .font(.largeTitle.bold())

                Text(String(localized: "Open a folder of Markdown files to start writing. An Obsidian vault works as it is."))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let message {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: AppSpacing.small) {
                Button(action: onOpen) {
                    Text(String(localized: "Open Vault…"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)

                Button(action: onCreate) {
                    Text(String(localized: "Create Vault…"))
                        .frame(maxWidth: .infinity)
                }
            }
            .controlSize(.large)

            if recents.isEmpty == false {
                recentVaults
            }
        }
        .frame(maxWidth: EditorMetrics.welcomeWidth)
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Recent Vaults

    private var recentVaults: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xsmall) {
            Text(String(localized: "Recent Vaults"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.small)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(recents) { vault in
                        RecentVaultRow(vault: vault, onChoose: { onChoose(vault) }, onRemove: { onRemove(vault) })
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(height: EditorMetrics.welcomeRecentRowHeight * CGFloat(min(recents.count, EditorMetrics.welcomeRecentMaxRows)))
        }
    }
}

#if DEBUG
    #Preview("First launch") {
        WelcomeView(message: nil)
    }

    #Preview("Recent Vaults") {
        WelcomeView(message: nil, recents: [
            RecentVault(record: RecentVaultRecord(bookmark: Data(), path: "/Vaults/Garden"), folderURL: URL(filePath: "/Vaults/Garden"), isMissing: false),
            RecentVault(record: RecentVaultRecord(bookmark: Data(), path: "/Vaults/Old"), folderURL: URL(filePath: "/Vaults/Old"), isMissing: true)
        ])
    }

    #Preview("Vault missing") {
        WelcomeView(message: "The Vault you used last can’t be found. It may have been moved or deleted, and this message is long enough to wrap.")
    }
#endif

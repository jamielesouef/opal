//
//  WelcomeView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalDesign
import SwiftUI

struct WelcomeView: View {
    // MARK: - Constants

    private enum Constants {
        static let iconSize: CGFloat = 96
    }

    // MARK: - Input

    let message: String?
    var onOpen: () -> Void = {}
    var onCreate: () -> Void = {}

    // MARK: - View

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: Constants.iconSize, height: Constants.iconSize)
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
        }
        .frame(maxWidth: EditorMetrics.welcomeWidth)
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
    #Preview("First launch") {
        WelcomeView(message: nil)
    }

    #Preview("Vault missing") {
        WelcomeView(message: "The Vault you used last can’t be found. It may have been moved or deleted, and this message is long enough to wrap.")
    }
#endif

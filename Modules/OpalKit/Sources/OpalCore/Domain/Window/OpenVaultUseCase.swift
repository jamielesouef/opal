//
//  OpenVaultUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

public enum OpenVaultUseCase {
    // MARK: - Decide

    public static func decide(opening folderURL: URL, from window: UUID, roots: [UUID: URL]) -> OpenVaultDecision {
        let wanted = normalized(folderURL)
        if let owner = roots.first(where: { normalized($0.value) == wanted })?.key {
            return owner == window ? .openHere : .bringToFront(owner)
        }

        return roots[window] == nil ? .openHere : .openInNewWindow
    }

    // MARK: - Private

    private static func normalized(_ url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().path(percentEncoded: false).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}

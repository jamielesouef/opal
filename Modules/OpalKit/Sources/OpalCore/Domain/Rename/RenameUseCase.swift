//
//  RenameUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum RenameUseCase {
    // MARK: - Constants

    private static let forbidden: Set<Character> = ["/", ":", "\\"]

    // MARK: - Validate

    public static func newPath(
        renaming path: NotePath,
        to name: String,
        kind: VaultItemKind,
        existing: Set<NotePath>
    ) -> Result<NotePath, RenameProblem> {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return .failure(.empty)
        }
        if let bad = trimmed.first(where: forbidden.contains) {
            return .failure(.invalidCharacter(bad))
        }
        guard trimmed.hasPrefix(".") == false else {
            return .failure(.startsWithDot)
        }

        let fileName: String
        switch kind {
        case .note:
            fileName = trimmed.lowercased().hasSuffix(".\(NotePath.noteExtension)") ? trimmed : "\(trimmed).\(NotePath.noteExtension)"
        case .attachment:
            fileName = (trimmed as NSString).pathExtension.isEmpty && path.fileExtension.isEmpty == false ? "\(trimmed).\(path.fileExtension)" : trimmed
        case .folder:
            fileName = trimmed
        }

        let target = path.parent.appending(fileName)
        guard target != path else {
            return .failure(.unchanged)
        }

        let clash = existing.first { $0 != path && $0.rawValue.lowercased() == target.rawValue.lowercased() }
        if let clash {
            return .failure(.taken(clash))
        }
        return .success(target)
    }
}

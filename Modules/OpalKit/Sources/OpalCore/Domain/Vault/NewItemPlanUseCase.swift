//
//  NewItemPlanUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum NewItemPlanUseCase {
    // MARK: - Constants

    public static let untitledName = "Untitled"

    // MARK: - Where

    public static func folderForNewNote(settings: ObsidianAppSettings, openNote: NotePath?) -> NotePath {
        switch settings.newFileLocation {
        case .root:
            return .root
        case .current:
            return openNote?.parent ?? .root
        case .folder:
            let folder = NotePath(settings.newFileFolderPath)
            guard folder.isWithinVault, folder.isHidden == false else {
                return .root
            }

            return folder
        }
    }

    public static func containingFolder(of path: NotePath?, kind: VaultItemKind?) -> NotePath {
        guard let path else {
            return .root
        }

        switch kind {
        case .folder:
            return path
        case .note,
             .attachment,
             nil:
            return path.parent
        }
    }

    // MARK: - Name

    public static func newNotePath(in folder: NotePath, existing: Set<NotePath>) -> NotePath {
        uniquePath(in: folder, existing: existing) { "\($0).\(NotePath.noteExtension)" }
    }

    public static func newFolderPath(in folder: NotePath, existing: Set<NotePath>) -> NotePath {
        uniquePath(in: folder, existing: existing) { $0 }
    }

    // MARK: - Private

    private static func uniquePath(
        in folder: NotePath,
        existing: Set<NotePath>,
        fileName: (String) -> String
    ) -> NotePath {
        let taken = Set(existing.map { $0.rawValue.lowercased() })
        var suffix = 0
        while true {
            let base = suffix == 0 ? untitledName : "\(untitledName) \(suffix)"
            let candidate = folder.appending(fileName(base))
            if taken.contains(candidate.rawValue.lowercased()) == false {
                return candidate
            }
            suffix += 1
        }
    }
}

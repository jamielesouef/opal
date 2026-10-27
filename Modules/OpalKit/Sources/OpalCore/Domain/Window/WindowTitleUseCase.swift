//
//  WindowTitleUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum WindowTitleUseCase {
    public static func title(vaultName: String, openNote: NotePath?) -> String {
        openNote?.name ?? vaultName
    }

    public static func subtitle(vaultName: String, openNote: NotePath?) -> String {
        guard let openNote else {
            return ""
        }

        let folder = openNote.parent
        return folder.isRoot ? vaultName : "\(vaultName)/\(folder.rawValue)"
    }
}

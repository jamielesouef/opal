//
//  DetailContentUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum DetailContentUseCase {
    public static func content(selection: NotePath?, kind: VaultItemKind?) -> DetailContent {
        guard let selection else {
            return .note
        }

        switch kind {
        case .attachment:
            return .attachment(selection)
        case .note,
             .folder,
             nil:
            return .note
        }
    }
}

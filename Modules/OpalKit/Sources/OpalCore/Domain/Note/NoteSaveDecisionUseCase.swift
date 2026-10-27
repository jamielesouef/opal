//
//  NoteSaveDecisionUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum NoteSaveDecisionUseCase {
    public static func decide(lastKnownDisk: String, draft: String, onDisk: String?) -> NoteSaveDecision {
        guard let onDisk else {
            return .recreate
        }

        switch (draft == lastKnownDisk, onDisk == lastKnownDisk, onDisk == draft) {
        case (true, true, _):
            return .unchanged
        case (true, false, _),
             (false, false, true):
            return .adoptDisk(onDisk)
        case (false, true, _):
            return .write
        case (false, false, false):
            return .conflict(diskText: onDisk)
        }
    }
}

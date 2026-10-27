//
//  IndexSyncPlanUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum IndexSyncPlanUseCase {
    // MARK: - Plan

    public static func plan(disk: [NotePath: FileStamp], indexed: [NotePath: FileStamp]) -> IndexSyncPlan {
        let toRead = disk
            .filter { indexed[$0.key] != $0.value }
            .map(\.key)
            .sorted { $0.rawValue < $1.rawValue }
        let toRemove = indexed.keys
            .filter { disk[$0] == nil }
            .sorted { $0.rawValue < $1.rawValue }
        return IndexSyncPlan(toRead: toRead, toRemove: toRemove)
    }
}

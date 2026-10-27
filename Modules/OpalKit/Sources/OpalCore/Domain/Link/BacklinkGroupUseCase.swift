//
//  BacklinkGroupUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public enum BacklinkGroupUseCase {
    // MARK: - Groups

    public static func groups(_ backlinks: [Backlink]) -> [BacklinkGroup] {
        var order: [NotePath] = []
        var bySource: [NotePath: [Backlink]] = [:]
        for backlink in backlinks {
            if bySource[backlink.source] == nil {
                order.append(backlink.source)
            }
            bySource[backlink.source, default: []].append(backlink)
        }
        return order.map { BacklinkGroup(source: $0, backlinks: bySource[$0] ?? []) }
    }

    // MARK: - Context

    public static func context(of backlink: Backlink) -> String {
        backlink.link.lineText.trimmingCharacters(in: .whitespaces)
    }
}

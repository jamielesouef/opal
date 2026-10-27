//
//  LinkMap.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public struct LinkMap: Sendable {
    // MARK: - Constants

    public static let empty = LinkMap(paths: [], parsed: [:])

    // MARK: - Stored

    public let parsed: [NotePath: ParsedNote]
    public let resolver: LinkResolver

    private let backlinksByTarget: [NotePath: [Backlink]]

    // MARK: - Init

    public init(paths: [NotePath], parsed: [NotePath: ParsedNote]) {
        let resolver = LinkResolver(paths: paths, aliases: parsed.compactMapValues { $0.aliases.isEmpty ? nil : $0.aliases })
        var backlinks: [NotePath: [Backlink]] = [:]
        for (source, note) in parsed {
            for link in note.links {
                guard let target = resolver.resolve(link.target, from: source), target != source else {
                    continue
                }
                backlinks[target, default: []].append(Backlink(source: source, link: link))
            }
        }

        self.parsed = parsed
        self.resolver = resolver
        backlinksByTarget = backlinks.mapValues { links in
            links.sorted { lhs, rhs in
                if lhs.source != rhs.source {
                    return lhs.source.name.localizedStandardCompare(rhs.source.name) == .orderedAscending
                }
                return lhs.link.span.location < rhs.link.span.location
            }
        }
    }

    // MARK: - Reads

    public func backlinks(to target: NotePath) -> [Backlink] {
        backlinksByTarget[target] ?? []
    }

    public func outgoing(from source: NotePath, in note: ParsedNote) -> [OutgoingLink] {
        var seen: Set<String> = []
        return note.links.compactMap { link in
            let target = resolver.resolve(link.target, from: source)
            let key = target?.rawValue ?? link.target.lowercased()
            guard link.pointsAtSelf == false, seen.insert(key).inserted else {
                return nil
            }
            return OutgoingLink(link: link, target: target)
        }
    }

    public func highlights(in note: ParsedNote, from source: NotePath) -> [LinkHighlight] {
        note.links.map { LinkHighlight(span: $0.span, isResolved: resolver.resolve($0.target, from: source) != nil) }
    }
}

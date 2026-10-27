//
//  LinkFollowUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public enum LinkFollowUseCase {
    // MARK: - Destination

    public static func destination(
        for link: Link,
        from source: NotePath,
        map: LinkMap,
        settings: ObsidianAppSettings
    ) -> LinkDestination {
        guard let target = map.resolver.resolve(link.target, from: source) else {
            return newNotePath(for: link.target, settings: settings, openNote: source).map(LinkDestination.create) ?? .nowhere
        }

        guard target.isNote else {
            return .attachment(target)
        }

        return .note(target, line: link.subpath.flatMap { line(of: $0, in: map.parsed[target] ?? .empty) })
    }

    // MARK: - Lines

    public static func line(of subpath: LinkSubpath, in note: ParsedNote) -> Int? {
        switch subpath {
        case let .heading(text):
            let wanted = normalised(text.split(separator: "#").last.map(String.init) ?? text)
            return note.headings.first { normalised($0.text) == wanted }?.line
        case let .block(id):
            return note.blocks.first { $0.id.lowercased() == id.lowercased() }?.line
        }
    }

    // MARK: - New Note

    public static func newNotePath(for target: String, settings: ObsidianAppSettings, openNote: NotePath?) -> NotePath? {
        let trimmed = target.trimmingCharacters(in: .whitespaces)
        let suffix = ".\(NotePath.noteExtension)"
        let base = trimmed.lowercased().hasSuffix(suffix) ? String(trimmed.dropLast(suffix.count)) : trimmed
        let relative = NotePath(base)
        guard let name = relative.components.last, name.isEmpty == false else {
            return nil
        }

        let folder = relative.components.count > 1
            ? relative.parent
            : NewItemPlanUseCase.folderForNewNote(settings: settings, openNote: openNote)
        let path = folder.appending(name + suffix)
        guard path.isWithinVault, path.isHidden == false else {
            return nil
        }

        return path
    }

    // MARK: - Private

    private static func normalised(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespaces).lowercased()
    }
}

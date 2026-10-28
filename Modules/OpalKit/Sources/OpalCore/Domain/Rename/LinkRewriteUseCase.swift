//
//  LinkRewriteUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum LinkRewriteUseCase {
    // MARK: - Constants

    private static let markdownAllowed = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "()"))

    // MARK: - Rewrite

    public static func rewrite(
        _ text: String,
        links: [Link],
        source: NotePath,
        moves: [NotePath: NotePath],
        resolver: LinkResolver,
        isUniqueName: (NotePath) -> Bool
    ) -> String? {
        var result = text as NSString
        var changed = false
        for link in links.sorted(by: { $0.span.location > $1.span.location }) where link.target.isEmpty == false {
            guard let old = resolver.resolve(link.target, from: source), let new = moves[old] else {
                continue
            }

            let range = NSRange(location: link.span.location, length: link.span.length)
            guard NSMaxRange(range) <= result.length else {
                continue
            }

            let relative = isRelative(link.target, from: source, to: old)
            let replacement = linkText(link, to: new, source: moves[source] ?? source, isUniqueName: isUniqueName(new), isRelative: relative)
            result = result.replacingCharacters(in: range, with: replacement) as NSString
            changed = true
        }
        return changed ? result as String : nil
    }

    public static func linkText(_ link: Link, to target: NotePath, source: NotePath, isUniqueName: Bool, isRelative: Bool = false) -> String {
        let bang = link.isEmbed ? "!" : ""
        let subpath: String = switch link.subpath {
        case let .heading(heading):
            "#\(heading)"
        case let .block(block):
            "#^\(block)"
        case nil:
            ""
        }

        switch link.style {
        case .wiki:
            let alias = link.displayText.map { "|\($0)" } ?? ""
            return "\(bang)[[\(wikiTarget(old: link.target, new: target, isUniqueName: isUniqueName))\(subpath)\(alias)]]"
        case .markdown:
            let destination = markdownTarget(old: link.target, new: target, source: source, isUniqueName: isUniqueName, isRelative: isRelative)
            let encoded = (destination.addingPercentEncoding(withAllowedCharacters: markdownAllowed) ?? destination) + (subpath.addingPercentEncoding(withAllowedCharacters: markdownAllowed) ?? subpath)
            return "\(bang)[\(link.displayText ?? "")](\(encoded))"
        }
    }

    // MARK: - Private

    private static func wikiTarget(old: String, new: NotePath, isUniqueName: Bool) -> String {
        let keepsExtension = new.isNote == false || old.lowercased().hasSuffix(".\(NotePath.noteExtension)")
        if old.contains("/") == false, isUniqueName {
            return keepsExtension ? new.fileName : new.name
        }
        return keepsExtension ? new.rawValue : String(new.rawValue.dropLast(NotePath.noteExtension.count + 1))
    }

    private static func markdownTarget(old: String, new: NotePath, source: NotePath, isUniqueName: Bool, isRelative: Bool) -> String {
        if old.contains("/") == false, isUniqueName {
            return new.fileName
        }
        return isRelative ? relative(new, from: source.parent) : new.rawValue
    }

    private static func isRelative(_ target: String, from source: NotePath, to file: NotePath) -> Bool {
        guard target.contains("/") else {
            return false
        }
        if target.hasPrefix("./") || target.hasPrefix("../") {
            return true
        }
        let joined = (source.parent.components + target.split(separator: "/").map(String.init)).joined(separator: "/").lowercased()
        return source.parent.isRoot == false && (joined == file.rawValue.lowercased() || joined + ".md" == file.rawValue.lowercased())
    }

    static func relative(_ path: NotePath, from folder: NotePath) -> String {
        var shared = 0
        while shared < folder.components.count, shared < path.components.count - 1, folder.components[shared] == path.components[shared] {
            shared += 1
        }
        let ups = Array(repeating: "..", count: folder.components.count - shared)
        return (ups + path.components[shared...]).joined(separator: "/")
    }
}

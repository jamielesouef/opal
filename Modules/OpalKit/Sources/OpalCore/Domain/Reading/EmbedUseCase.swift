//
//  EmbedUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum EmbedUseCase {
    // MARK: - Constants

    private static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "heic", "tif", "tiff", "avif"]

    // MARK: - Media

    public static func media(of path: NotePath) -> EmbedMedia {
        guard path.isNote == false else {
            return .note
        }

        let pathExtension = (path.rawValue as NSString).pathExtension.lowercased()
        if imageExtensions.contains(pathExtension) {
            return .image
        }
        return pathExtension == "pdf" ? .pdf : .file
    }

    public static func width(from displayText: String?) -> Int? {
        guard let displayText, let first = displayText.split(separator: "x").first else {
            return nil
        }

        return Int(first.trimmingCharacters(in: .whitespaces))
    }

    // MARK: - Sections

    public static func lines(for subpath: LinkSubpath?, in parsed: ParsedNote, lineCount: Int, isBlank: (Int) -> Bool) -> Range<Int>? {
        guard let subpath else {
            return 0 ..< lineCount
        }

        guard let start = LinkFollowUseCase.line(of: subpath, in: parsed) else {
            return nil
        }

        switch subpath {
        case .heading:
            let level = parsed.headings.first { $0.line == start }?.level ?? 1
            let end = parsed.headings.first { $0.line > start && $0.level <= level }?.line ?? lineCount
            return start ..< end
        case .block:
            var first = start
            while first > 0, isBlank(first - 1) == false {
                first -= 1
            }
            return first ..< start + 1
        }
    }
}

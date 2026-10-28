//
//  AttachmentUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum AttachmentUseCase {
    // MARK: - Constants

    private enum Constants {
        static let sameFolder = "./"
        static let pastedPrefix = "Pasted image "
        static let pastedExtension = "png"
        static let stampFormat = "yyyyMMddHHmmss"
        static let maximumSuffix = 999
    }

    // MARK: - Place

    public static func folder(for note: NotePath, attachmentFolderPath: String) -> NotePath {
        let setting = attachmentFolderPath.trimmingCharacters(in: .whitespaces)
        if setting == "." || setting == Constants.sameFolder {
            return note.parent
        }
        if setting.hasPrefix(Constants.sameFolder) {
            return NotePath(components: note.parent.components + NotePath(String(setting.dropFirst(Constants.sameFolder.count))).components)
        }
        return NotePath(setting)
    }

    public static func pastedName(at date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = Constants.stampFormat
        return Constants.pastedPrefix + formatter.string(from: date) + "." + Constants.pastedExtension
    }

    public static func availablePath(named fileName: String, in folder: NotePath, existing: Set<NotePath>) -> NotePath? {
        let base = (fileName as NSString).deletingPathExtension
        let fileExtension = (fileName as NSString).pathExtension
        let lowered = Set(existing.map { $0.rawValue.lowercased() })
        for suffix in 0 ... Constants.maximumSuffix {
            let name = suffix == 0 ? base : "\(base) \(suffix)"
            let path = folder.appending(fileExtension.isEmpty ? name : "\(name).\(fileExtension)")
            guard path.isWithinVault else {
                return nil
            }
            if lowered.contains(path.rawValue.lowercased()) == false {
                return path
            }
        }
        return nil
    }

    // MARK: - Embed

    public static func embedText(for attachment: NotePath, from note: NotePath, existing: Set<NotePath>, settings: ObsidianAppSettings) -> String {
        let target: String
        switch settings.newLinkFormat {
        case .shortest:
            let sameName = existing.filter { $0.fileName.lowercased() == attachment.fileName.lowercased() }
            target = sameName.subtracting([attachment]).isEmpty ? attachment.fileName : attachment.rawValue
        case .absolute:
            target = attachment.rawValue
        case .relative:
            target = relative(attachment, from: note.parent)
        }

        guard settings.useMarkdownLinks else {
            return "![[\(target)]]"
        }

        let encoded = target.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "()"))) ?? target
        return "![](\(encoded))"
    }

    // MARK: - Private

    private static func relative(_ path: NotePath, from folder: NotePath) -> String {
        var shared = 0
        while shared < folder.components.count, shared < path.components.count - 1, folder.components[shared] == path.components[shared] {
            shared += 1
        }
        let ups = Array(repeating: "..", count: folder.components.count - shared)
        return (ups + path.components[shared...]).joined(separator: "/")
    }
}

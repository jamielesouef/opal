//
//  FileSystemVaultStore.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public actor FileSystemVaultStore: VaultFileStoring {
    // MARK: - Constants

    private enum Constants {
        static let obsidianFolder = ".obsidian"
        static let walkKeys: [URLResourceKey] = [
            .isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey, .contentModificationDateKey, .fileSizeKey
        ]
    }

    // MARK: - Private

    public nonisolated let rootURL: URL

    private let fileManager = FileManager()

    // MARK: - Init

    private let trashFolderURL: URL?

    public init(rootURL: URL, trashFolderURL: URL? = nil) {
        self.rootURL = rootURL.standardizedFileURL
        self.trashFolderURL = trashFolderURL
    }

    // MARK: - VaultFileStoring

    public func listEntries() throws(VaultError) -> [VaultEntry] {
        var entries: [VaultEntry] = []
        try walk { path, type, _ in
            if type == .typeDirectory {
                entries.append(VaultEntry(path: path, isFolder: true))
            } else if type == .typeRegular {
                entries.append(VaultEntry(path: path, isFolder: false))
            }
        }
        return entries
    }

    public func noteStamps() throws(VaultError) -> [NotePath: FileStamp] {
        var stamps: [NotePath: FileStamp] = [:]
        try walk { path, type, attributes in
            guard type == .typeRegular, path.isNote else {
                return
            }
            stamps[path] = Self.stamp(from: attributes)
        }
        return stamps
    }

    public func stamp(of path: NotePath) -> FileStamp? {
        guard path.isRoot == false, path.isWithinVault,
              let attributes = try? fileManager.attributesOfItem(atPath: url(for: path).path),
              attributes[.type] as? FileAttributeType == .typeRegular
        else {
            return nil
        }

        return Self.stamp(from: attributes)
    }

    public func readNote(at path: NotePath) throws(VaultError) -> String? {
        let url = try checkedURL(for: path)
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        guard isSymbolicLink(url) == false else {
            throw .outsideVault
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw .unreadable(path)
        }

        guard let text = String(validating: data, as: UTF8.self) else {
            throw .notUTF8(path)
        }

        return text
    }

    public func writeNote(_ text: String, at path: NotePath) throws(VaultError) {
        let url = try checkedURL(for: path)
        guard isSymbolicLink(url) == false else {
            throw .outsideVault
        }

        do {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(text.utf8).write(to: url, options: .atomic)
        } catch {
            throw .writeFailed(path)
        }
    }

    public func createNote(at path: NotePath, text: String) throws(VaultError) {
        let url = try checkedURL(for: path)
        guard fileManager.fileExists(atPath: url.path) == false else {
            throw .alreadyExists(path)
        }

        do {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(text.utf8).write(to: url, options: .withoutOverwriting)
        } catch {
            throw .writeFailed(path)
        }
    }

    public func createFile(at path: NotePath, data: Data) throws(VaultError) {
        let url = try checkedURL(for: path)
        guard fileManager.fileExists(atPath: url.path) == false else {
            throw .alreadyExists(path)
        }

        do {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .withoutOverwriting)
        } catch {
            throw .writeFailed(path)
        }
    }

    public func trashItem(at path: NotePath) throws(VaultError) {
        let url = try checkedURL(for: path)
        guard fileManager.fileExists(atPath: url.path) else {
            throw .notFound(path)
        }

        do {
            if let trashFolderURL {
                try fileManager.createDirectory(at: trashFolderURL, withIntermediateDirectories: true)
                try fileManager.moveItem(at: url, to: trashFolderURL.appending(path: "\(UUID().uuidString)-\(path.fileName)"))
            } else {
                try fileManager.trashItem(at: url, resultingItemURL: nil)
            }
        } catch {
            throw .writeFailed(path)
        }
    }

    public func moveItem(from source: NotePath, to destination: NotePath) throws(VaultError) {
        let from = try checkedURL(for: source)
        let to = try checkedURL(for: destination)
        guard fileManager.fileExists(atPath: from.path), isSymbolicLink(from) == false else {
            throw .notFound(source)
        }

        let caseOnly = source.rawValue.lowercased() == destination.rawValue.lowercased()
        guard caseOnly || fileManager.fileExists(atPath: to.path) == false else {
            throw .alreadyExists(destination)
        }

        do {
            try fileManager.createDirectory(at: to.deletingLastPathComponent(), withIntermediateDirectories: true)
            if caseOnly {
                let step = from.deletingLastPathComponent().appending(path: ".opal-rename-\(UUID().uuidString)")
                try fileManager.moveItem(at: from, to: step)
                try fileManager.moveItem(at: step, to: to)
            } else {
                try fileManager.moveItem(at: from, to: to)
            }
        } catch {
            throw .writeFailed(destination)
        }
    }

    public func createFolder(at path: NotePath) throws(VaultError) {
        let url = try checkedURL(for: path)
        guard fileManager.fileExists(atPath: url.path) == false else {
            throw .alreadyExists(path)
        }

        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw .writeFailed(path)
        }
    }

    public func readObsidianSettings(named fileName: String) -> Data? {
        let path = NotePath(components: [Constants.obsidianFolder, fileName])
        guard path.isWithinVault else {
            return nil
        }

        return try? Data(contentsOf: url(for: path))
    }

    public nonisolated func url(for path: NotePath) -> URL {
        path.components.reduce(rootURL) { $0.appending(component: $1) }
    }

    // MARK: - Private

    private func walk(_ visit: (NotePath, FileAttributeType?, [FileAttributeKey: Any]) -> Void) throws(VaultError) {
        guard isDirectory(rootURL),
              let enumerator = fileManager.enumerator(at: rootURL.resolvingSymlinksInPath(), includingPropertiesForKeys: Constants.walkKeys)
        else {
            throw .folderUnreadable
        }

        let prefixes = rootPrefixes()
        while let url = enumerator.nextObject() as? URL {
            guard let prefix = prefixes.first(where: { url.path.hasPrefix($0) }) else {
                continue
            }

            let path = NotePath(String(url.path.dropFirst(prefix.count)))
            let values = try? url.resourceValues(forKeys: Set(Constants.walkKeys))
            guard path.isHidden == false, values?.isSymbolicLink != true else {
                if values?.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }

            let type: FileAttributeType? = if values?.isDirectory == true {
                .typeDirectory
            } else if values?.isRegularFile == true {
                .typeRegular
            } else {
                nil
            }
            var attributes: [FileAttributeKey: Any] = [:]
            attributes[.modificationDate] = values?.contentModificationDate
            attributes[.size] = values?.fileSize.map(NSNumber.init(value:))
            visit(path, type, attributes)
        }
    }

    private func rootPrefixes() -> [String] {
        let standard = rootURL.path
        let real = realpath(standard, nil).map { pointer in
            defer { free(pointer) }
            return String(cString: pointer)
        } ?? standard
        return [standard, real].map { $0.hasSuffix("/") ? $0 : $0 + "/" }
    }

    private static func stamp(from attributes: [FileAttributeKey: Any]) -> FileStamp {
        FileStamp(
            modified: attributes[.modificationDate] as? Date ?? .distantPast,
            size: (attributes[.size] as? NSNumber)?.intValue ?? 0
        )
    }

    private func checkedURL(for path: NotePath) throws(VaultError) -> URL {
        guard path.isRoot == false, path.isWithinVault else {
            throw .outsideVault
        }

        return url(for: path)
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func isSymbolicLink(_ url: URL) -> Bool {
        let type = try? fileManager.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType
        return type == .typeSymbolicLink
    }
}

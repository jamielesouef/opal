//
//  FSEventsVaultWatcher.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import CoreServices
import Foundation

public final class FSEventsVaultWatcher: VaultWatching {
    // MARK: - Constants

    private enum Constants {
        static let latency: CFTimeInterval = 0.3
        static let queueLabel = "com.jamielesouef.Opal.vault-watcher"
        static let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagFileEvents
                | kFSEventStreamCreateFlagUseCFTypes
                | kFSEventStreamCreateFlagNoDefer
                | kFSEventStreamCreateFlagWatchRoot
        )
    }

    // MARK: - Stored

    public let rootURL: URL

    // MARK: - Init

    public init(rootURL: URL) {
        self.rootURL = rootURL
    }

    // MARK: - VaultWatching

    public func changes() -> AsyncStream<Set<NotePath>> {
        AsyncStream { continuation in
            let receiver = FSEventsStreamContext(rootURL: rootURL, continuation: continuation)
            var context = FSEventStreamContext(
                version: 0,
                info: Unmanaged.passRetained(receiver).toOpaque(),
                retain: nil,
                release: { info in
                    guard let info else {
                        return
                    }
                    Unmanaged<FSEventsStreamContext>.fromOpaque(info).release()
                },
                copyDescription: nil
            )

            guard let stream = FSEventStreamCreate(
                nil,
                Self.callback,
                &context,
                [rootURL.path] as CFArray,
                FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                Constants.latency,
                Constants.flags
            ) else {
                AppLog.error("Watching the Vault failed: FSEventStreamCreate returned nil")
                continuation.finish()
                return
            }

            FSEventStreamSetDispatchQueue(stream, DispatchQueue(label: Constants.queueLabel))
            guard FSEventStreamStart(stream) else {
                AppLog.error("Watching the Vault failed: FSEventStreamStart returned false")
                FSEventsStreamHandle(stream: stream).stop()
                continuation.finish()
                return
            }

            let handle = FSEventsStreamHandle(stream: stream)
            continuation.onTermination = { _ in
                handle.stop()
            }
        }
    }

    // MARK: - Private

    private static let callback: FSEventStreamCallback = { _, info, _, eventPaths, _, _ in
        guard let info else {
            return
        }

        let receiver = Unmanaged<FSEventsStreamContext>.fromOpaque(info).takeUnretainedValue()
        let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as? [String] ?? []
        receiver.receive(paths)
    }
}

//
//  FSEventsStreamHandle.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import CoreServices

final class FSEventsStreamHandle: @unchecked Sendable {
    // MARK: - Stored

    private let stream: FSEventStreamRef

    // MARK: - Init

    init(stream: FSEventStreamRef) {
        self.stream = stream
    }

    // MARK: - Stop

    func stop() {
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
    }
}

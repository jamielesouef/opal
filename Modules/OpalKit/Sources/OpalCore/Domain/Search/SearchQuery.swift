//
//  SearchQuery.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct SearchQuery: Hashable, Sendable {
    // MARK: - Stored

    public var words: [String] = []
    public var phrases: [String] = []
    public var excluded: [String] = []
    public var paths: [String] = []
    public var files: [String] = []
    public var tags: [String] = []

    // MARK: - Init

    public init(
        words: [String] = [],
        phrases: [String] = [],
        excluded: [String] = [],
        paths: [String] = [],
        files: [String] = [],
        tags: [String] = []
    ) {
        self.words = words
        self.phrases = phrases
        self.excluded = excluded
        self.paths = paths
        self.files = files
        self.tags = tags
    }

    // MARK: - Derived

    public var isEmpty: Bool {
        words.isEmpty && phrases.isEmpty && paths.isEmpty && files.isEmpty && tags.isEmpty
    }

    public var hasTextTerms: Bool {
        words.isEmpty == false || phrases.isEmpty == false
    }

    public var highlightTerms: [String] {
        phrases + words + tags.map { "#" + $0 }
    }
}

//
//  FTSQueryBuilder.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

enum FTSQueryBuilder {
    // MARK: - Match

    static func match(for query: SearchQuery) -> String? {
        guard query.hasTextTerms else {
            return nil
        }

        let phrases = query.phrases.map(quoted)
        let words = query.words.enumerated().map { index, word in
            index == query.words.count - 1 ? quoted(word) + "*" : quoted(word)
        }
        let positive = (phrases + words).joined(separator: " ")
        let negative = query.excluded.map { " NOT " + quoted($0) }.joined()
        return positive + negative
    }

    // MARK: - LIKE

    static func likePattern(containing value: String) -> String {
        "%" + escapedForLike(value) + "%"
    }

    static func tagPatterns(for tag: String) -> (exact: String, child: String) {
        let escaped = escapedForLike(tag.lowercased())
        return ("% " + escaped + " %", "% " + escaped + "/%")
    }

    static func tagColumn(for tags: [String]) -> String {
        " " + tags.map { $0.lowercased() }.joined(separator: " ") + " "
    }

    // MARK: - Private

    private static func quoted(_ term: String) -> String {
        "\"" + term.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func escapedForLike(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }
}

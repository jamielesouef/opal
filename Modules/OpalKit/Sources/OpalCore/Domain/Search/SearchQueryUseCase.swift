//
//  SearchQueryUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum SearchQueryUseCase {
    // MARK: - Parse

    public static func parse(_ text: String) -> SearchQuery {
        var query = SearchQuery()
        for token in tokens(in: text) {
            switch token {
            case let .phrase(phrase):
                query.phrases.append(phrase)
            case let .word(word):
                apply(word, to: &query)
            }
        }
        return query
    }

    // MARK: - Private

    private enum Token {
        case word(String)
        case phrase(String)
    }

    private static func apply(_ word: String, to query: inout SearchQuery) {
        let lower = word.lowercased()
        if lower.hasPrefix("path:"), word.count > 5 {
            query.paths.append(unquoted(String(word.dropFirst(5))))
        } else if lower.hasPrefix("file:"), word.count > 5 {
            query.files.append(unquoted(String(word.dropFirst(5))))
        } else if lower.hasPrefix("tag:"), word.count > 4 {
            let tag = unquoted(String(word.dropFirst(4)))
            query.tags.append(tag.hasPrefix("#") ? String(tag.dropFirst()) : tag)
        } else if word.hasPrefix("-"), word.count > 1 {
            query.excluded.append(String(word.dropFirst()))
        } else {
            query.words.append(word)
        }
    }

    private static func tokens(in text: String) -> [Token] {
        var tokens: [Token] = []
        var current = ""
        var inQuotes = false
        var startedWithQuote = false

        func flush() {
            if current.isEmpty == false {
                tokens.append(startedWithQuote ? .phrase(current) : .word(current))
            }
            current = ""
            startedWithQuote = false
        }

        for character in text {
            if character == "\"" {
                if current.isEmpty, inQuotes == false {
                    startedWithQuote = true
                }
                inQuotes.toggle()
            } else if character.isWhitespace, inQuotes == false {
                flush()
            } else {
                current.append(character)
            }
        }
        flush()
        return tokens
    }

    private static func unquoted(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "")
    }
}

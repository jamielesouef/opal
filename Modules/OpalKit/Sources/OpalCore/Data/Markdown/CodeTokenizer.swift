//
//  CodeTokenizer.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum CodeTokenizer {
    // MARK: - Languages

    private struct Grammar {
        let keywords: Set<String>
        let lineComments: [String]
        let blockComment: (open: String, close: String)?
        let quotes: Set<Character>
        let keysBeforeColon: Bool
    }

    private static let cStyle = (open: "/*", close: "*/")

    private static let grammars: [String: Grammar] = {
        let swift = Grammar(
            keywords: ["let", "var", "func", "if", "else", "guard", "return", "for", "in", "while", "switch", "case", "default", "struct", "class", "enum", "protocol", "extension", "import", "public", "private", "internal", "static", "self", "Self", "true", "false", "nil", "throws", "throw", "try", "await", "async", "init", "some", "any", "where", "break", "continue", "do", "catch", "final", "override", "mutating", "inout", "typealias", "actor"],
            lineComments: ["//"], blockComment: cStyle, quotes: ["\""], keysBeforeColon: false
        )
        let python = Grammar(
            keywords: ["def", "class", "return", "if", "elif", "else", "for", "in", "while", "import", "from", "as", "with", "try", "except", "finally", "raise", "pass", "break", "continue", "lambda", "yield", "None", "True", "False", "and", "or", "not", "is", "async", "await", "global", "nonlocal", "self"],
            lineComments: ["#"], blockComment: nil, quotes: ["\"", "'"], keysBeforeColon: false
        )
        let javaScript = Grammar(
            keywords: ["const", "let", "var", "function", "return", "if", "else", "for", "of", "in", "while", "switch", "case", "default", "class", "extends", "new", "this", "import", "export", "from", "true", "false", "null", "undefined", "async", "await", "try", "catch", "finally", "throw", "typeof", "instanceof", "break", "continue", "interface", "type"],
            lineComments: ["//"], blockComment: cStyle, quotes: ["\"", "'", "`"], keysBeforeColon: false
        )
        let json = Grammar(keywords: ["true", "false", "null"], lineComments: [], blockComment: nil, quotes: ["\""], keysBeforeColon: false)
        let yaml = Grammar(keywords: ["true", "false", "null", "yes", "no"], lineComments: ["#"], blockComment: nil, quotes: ["\"", "'"], keysBeforeColon: true)
        let shell = Grammar(
            keywords: ["if", "then", "else", "elif", "fi", "for", "in", "do", "done", "while", "case", "esac", "function", "return", "export", "local", "echo", "cd", "set", "unset", "exit"],
            lineComments: ["#"], blockComment: nil, quotes: ["\"", "'"], keysBeforeColon: false
        )
        return [
            "swift": swift, "python": python, "py": python,
            "javascript": javaScript, "js": javaScript, "typescript": javaScript, "ts": javaScript, "jsx": javaScript, "tsx": javaScript,
            "json": json, "yaml": yaml, "yml": yaml,
            "shell": shell, "sh": shell, "bash": shell, "zsh": shell, "console": shell
        ]
    }()

    // MARK: - Tokens

    public static func tokens(in code: String, language: String?) -> [CodeToken] {
        guard let language, let grammar = grammars[language.lowercased()] else {
            return []
        }

        let units = Array(code.utf16)
        var tokens: [CodeToken] = []
        var index = 0
        var lineStart = true
        while index < units.count {
            let unit = units[index]
            if unit == 0x0A {
                lineStart = true
                index += 1
                continue
            }

            if let block = grammar.blockComment, starts(block.open, units, at: index) {
                let end = find(block.close, units, from: index + 2).map { $0 + 2 } ?? units.count
                tokens.append(token(index, end, .comment))
                index = end
                continue
            }

            if grammar.lineComments.contains(where: { starts($0, units, at: index) }) {
                let end = units[index...].firstIndex(of: 0x0A) ?? units.count
                tokens.append(token(index, end, .comment))
                index = end
                continue
            }

            if let scalar = Unicode.Scalar(unit), grammar.quotes.contains(Character(scalar)) {
                var end = index + 1
                while end < units.count, units[end] != unit, units[end] != 0x0A {
                    end += units[end] == UInt16(UInt8(ascii: "\\")) ? 2 : 1
                }
                end = min(end + 1, units.count)
                tokens.append(token(index, end, isKey(units, after: end, grammar) ? .keyword : .string))
                index = end
                lineStart = false
                continue
            }

            if isIdentifierStart(unit) {
                var end = index + 1
                while end < units.count, isIdentifierPart(units[end]) {
                    end += 1
                }
                let word = String(utf16CodeUnits: Array(units[index ..< end]), count: end - index)
                if grammar.keywords.contains(word) || (lineStart && isKey(units, after: end, grammar)) {
                    tokens.append(token(index, end, .keyword))
                }
                index = end
                lineStart = false
                continue
            }

            if isDigit(unit), index == 0 || isIdentifierPart(units[index - 1]) == false {
                var end = index + 1
                while end < units.count, isIdentifierPart(units[end]) || units[end] == UInt16(UInt8(ascii: ".")) {
                    end += 1
                }
                tokens.append(token(index, end, .number))
                index = end
                lineStart = false
                continue
            }

            if unit != 0x20, unit != 0x09, unit != UInt16(UInt8(ascii: "-")) {
                lineStart = false
            }
            index += 1
        }
        return tokens
    }

    // MARK: - Private

    private static func token(_ start: Int, _ end: Int, _ kind: CodeTokenKind) -> CodeToken {
        CodeToken(span: TextSpan(location: start, length: end - start), kind: kind)
    }

    private static func starts(_ prefix: String, _ units: [UInt16], at index: Int) -> Bool {
        let prefixUnits = Array(prefix.utf16)
        return index + prefixUnits.count <= units.count && Array(units[index ..< index + prefixUnits.count]) == prefixUnits
    }

    private static func find(_ text: String, _ units: [UInt16], from index: Int) -> Int? {
        var position = index
        while position < units.count {
            if starts(text, units, at: position) {
                return position
            }
            position += 1
        }
        return nil
    }

    private static func isKey(_ units: [UInt16], after end: Int, _ grammar: Grammar) -> Bool {
        grammar.keysBeforeColon && end < units.count && units[end] == UInt16(UInt8(ascii: ":"))
    }

    private static func isIdentifierStart(_ unit: UInt16) -> Bool {
        (unit >= 0x41 && unit <= 0x5A) || (unit >= 0x61 && unit <= 0x7A) || unit == 0x5F || unit == 0x24
    }

    private static func isIdentifierPart(_ unit: UInt16) -> Bool {
        isIdentifierStart(unit) || isDigit(unit)
    }

    private static func isDigit(_ unit: UInt16) -> Bool {
        unit >= 0x30 && unit <= 0x39
    }
}

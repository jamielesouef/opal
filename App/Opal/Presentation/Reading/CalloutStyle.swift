//
//  CalloutStyle.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

enum CalloutStyle {
    // MARK: - Icons

    static func systemImage(for type: String) -> String {
        switch type {
        case "info":
            "info.circle"
        case "tip", "hint", "important":
            "flame"
        case "success", "check", "done":
            "checkmark.circle"
        case "question", "help", "faq":
            "questionmark.circle"
        case "warning", "caution", "attention":
            "exclamationmark.triangle"
        case "failure", "fail", "missing":
            "xmark.circle"
        case "danger", "error":
            "bolt"
        case "bug":
            "ladybug"
        case "example":
            "list.bullet"
        case "quote", "cite":
            "quote.opening"
        case "abstract", "summary", "tldr":
            "doc.text"
        case "todo":
            "checklist"
        default:
            "pencil"
        }
    }

    static func title(for type: String) -> String {
        type.prefix(1).uppercased() + type.dropFirst()
    }
}

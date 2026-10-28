//
//  EmbedContent.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public enum EmbedContent: Hashable, Sendable {
    case note(path: NotePath, title: String, blocks: [ReadingBlock])
    case image(path: NotePath, width: Int?)
    case pdf(NotePath)
    case file(NotePath)
    case unresolved(String)
    case recursive(NotePath)
}

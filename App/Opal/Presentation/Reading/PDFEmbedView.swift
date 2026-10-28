//
//  PDFEmbedView.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import PDFKit
import SwiftUI

struct PDFEmbedView: NSViewRepresentable {
    // MARK: - Input

    let url: URL

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.document = PDFDocument(url: url)
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        if view.document?.documentURL != url {
            view.document = PDFDocument(url: url)
        }
    }
}

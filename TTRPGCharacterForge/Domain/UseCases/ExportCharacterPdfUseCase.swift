//
//  ExportCharacterPdfUseCase.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Coordinates character validation and PDF export.
struct ExportCharacterPdfUseCase {
    private let exporter: PdfExporter

    init(exporter: PdfExporter) {
        self.exporter = exporter
    }

    func execute(character: CharacterDocument, catalog: RulesCatalog) throws -> URL {
        try exporter.export(character, catalog: catalog)
    }
}

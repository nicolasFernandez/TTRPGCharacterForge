//
//  PdfExporter.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation
 
/// Exports a character and its derived statistics as a PDF document.
protocol PdfExporter {
    func export(_ character: CharacterDocument, catalog: RulesCatalog) throws -> URL
}

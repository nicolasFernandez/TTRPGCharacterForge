//
//  ExportViewModel.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Coordinates character-sheet export and share-sheet presentation.
final class ExportViewModel: ObservableObject {
    private let exportCharacterPdfUseCase: ExportCharacterPdfUseCase
    
    init(exportCharacterPdfUseCase: ExportCharacterPdfUseCase) {
        self.exportCharacterPdfUseCase = exportCharacterPdfUseCase
    }
}

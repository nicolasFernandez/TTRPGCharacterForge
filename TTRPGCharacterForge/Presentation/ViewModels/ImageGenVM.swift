//
//  ImageGenViewModel.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

final class ImageGenViewModel: ObservableObject {
    private let generateCharacterArtUseCase: GenerateCharacterArtUseCase

    init(generateCharacterArtUseCase: GenerateCharacterArtUseCase) {
        self.generateCharacterArtUseCase = generateCharacterArtUseCase
    }
}

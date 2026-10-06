//
//  GenerateVTTTokenUseCase.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Platform adapter for circular, transparent PNG rendering.
protocol TokenRendering {
    func render(imageData: Data, crop: NormalizedCrop) throws -> Data
}

/// Writes a virtual-tabletop token rendered by an injected platform adapter.
struct GenerateVTTTokenUseCase {
    let renderer: any TokenRendering

    enum TokenError: LocalizedError {
        case invalidImage
        case encodingFailed
        var errorDescription: String? {
            NSLocalizedString("token_export_failed", comment: "VTT token export failure")
        }
    }


    func execute(imageData: Data, filename: String, crop: NormalizedCrop = .fullImage) throws -> URL {
        let data = try renderer.render(imageData: imageData, crop: crop)
        let safe = filename.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "-", options: .regularExpression)
        let name = "\(safe.isEmpty ? "character" : safe)-\(UUID().uuidString)-token.png"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }
}

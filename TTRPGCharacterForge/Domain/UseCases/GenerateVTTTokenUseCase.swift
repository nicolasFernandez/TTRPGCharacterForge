//
//  GenerateVTTTokenUseCase.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Produces a virtual-tabletop token from a character portrait.
struct GenerateVTTTokenUseCase {
    enum TokenError: LocalizedError {
        case invalidImage
        case encodingFailed
        var errorDescription: String? { "The portrait could not be converted to a VTT token." }
    }

#if canImport(UIKit)
    func execute(imageData: Data, filename: String, crop: NormalizedCrop = .fullImage) throws -> URL {
        guard let loaded = UIImage(data: imageData) else { throw TokenError.invalidImage }
        let normalized = normalize(loaded)
        guard let cgImage = normalized.cgImage else { throw TokenError.invalidImage }
        let pixelCrop = CGRect(
            x: CGFloat(crop.x) * CGFloat(cgImage.width),
            y: CGFloat(crop.y) * CGFloat(cgImage.height),
            width: CGFloat(crop.width) * CGFloat(cgImage.width),
            height: CGFloat(crop.height) * CGFloat(cgImage.height)
        ).integral.intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        guard let cropped = cgImage.cropping(to: pixelCrop), pixelCrop.width > 0, pixelCrop.height > 0 else {
            throw TokenError.invalidImage
        }
        let source = UIImage(cgImage: cropped)
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size, format: transparentFormat())
        let token = renderer.image { _ in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
            let scale = max(size.width / source.size.width, size.height / source.size.height)
            let drawn = CGSize(width: source.size.width * scale, height: source.size.height * scale)
            source.draw(in: CGRect(x: (size.width - drawn.width) / 2, y: (size.height - drawn.height) / 2, width: drawn.width, height: drawn.height))
        }
        guard let data = token.pngData() else { throw TokenError.encodingFailed }
        let safe = filename.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "-", options: .regularExpression)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safe.isEmpty ? "character" : safe)-token.png")
        try data.write(to: url, options: .atomic)
        return url
    }

    private func transparentFormat() -> UIGraphicsImageRendererFormat {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        return format
    }

    private func normalize(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: image.size)) }
    }
#endif
}

#if canImport(UIKit)
import UIKit
#endif

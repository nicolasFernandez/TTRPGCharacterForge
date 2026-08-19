//
//  PortraitStore.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Persists generated portraits in the app's local storage.
struct PortraitStore {
    private let fileManager: FileManager
    private let baseURL: URL

    init(fileManager: FileManager = .default, baseURL: URL? = nil) {
        self.fileManager = fileManager
        self.baseURL = baseURL ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Portraits", isDirectory: true)
    }

    func save(_ data: Data, for characterID: UUID, fileExtension: String = "jpg") throws -> PortraitReference {
        try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        let filename = "\(characterID.uuidString).\(fileExtension)"
        let destination = baseURL.appendingPathComponent(filename)
        try data.write(to: destination, options: .atomic)
        return PortraitReference(relativePath: filename, crop: .fullImage)
    }

    func url(for portrait: PortraitReference) -> URL {
        baseURL.appendingPathComponent(portrait.relativePath)
    }

    func duplicate(_ portrait: PortraitReference?, for characterID: UUID) throws -> PortraitReference? {
        guard let portrait else { return nil }
        let source = url(for: portrait)
        guard fileManager.fileExists(atPath: source.path) else { return nil }
        let ext = source.pathExtension.isEmpty ? "jpg" : source.pathExtension
        let destination = baseURL.appendingPathComponent("\(characterID.uuidString).\(ext)")
        try fileManager.copyItem(at: source, to: destination)
        return PortraitReference(relativePath: destination.lastPathComponent, crop: portrait.crop)
    }

    func delete(_ portrait: PortraitReference) throws {
        let target = url(for: portrait)
        if fileManager.fileExists(atPath: target.path) { try fileManager.removeItem(at: target) }
    }
}

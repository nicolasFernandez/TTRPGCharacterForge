//
//  PortraitStore.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Persists generated portraits in the app's local storage.
// FileManager operations are thread safe; this value keeps immutable manager and URL references.
// Injected managers and their delegates must not be mutated concurrently.
struct PortraitStore: @unchecked Sendable {
    private let fileManager: FileManager
    private let baseURL: URL

    init(fileManager: FileManager = .default, baseURL: URL? = nil) {
        self.fileManager = fileManager
        self.baseURL = baseURL ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Portraits", isDirectory: true)
    }

    func save(_ data: Data, for characterID: UUID, fileExtension: String = "jpg") throws -> PortraitReference {
        try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
        let filename = "\(characterID.uuidString)-\(UUID().uuidString).\(fileExtension)"
        let destination = try validatedURL(
            for: PortraitReference(relativePath: filename, crop: .fullImage), allowMissing: true
        )
        try data.write(to: destination, options: .atomic)
        return PortraitReference(relativePath: filename, crop: .fullImage)
    }

    func url(for portrait: PortraitReference) throws -> URL {
        try validatedURL(for: portrait, allowMissing: false)
    }

    private func validatedURL(for portrait: PortraitReference, allowMissing: Bool) throws -> URL {
        let path = portrait.relativePath
        guard !path.isEmpty, path == (path as NSString).lastPathComponent,
              path != ".", path != "..", !path.contains("\\") else {
            throw CocoaError(.fileReadInvalidFileName)
        }
        let root = baseURL.resolvingSymlinksInPath().standardizedFileURL
        let candidate = root.appendingPathComponent(path).standardizedFileURL
        guard candidate.deletingLastPathComponent() == root else {
            throw CocoaError(.fileReadInvalidFileName)
        }
        try validateFileEntry(at: candidate, allowMissing: allowMissing)
        return candidate
    }

    private func validateFileEntry(at candidate: URL, allowMissing: Bool) throws {
        do {
            // Inspect the entry itself: symbolic links, including dangling links, are not regular files.
            let attributes = try fileManager.attributesOfItem(atPath: candidate.path)
            guard attributes[.type] as? FileAttributeType == .typeRegular else {
                throw CocoaError(.fileReadInvalidFileName)
            }
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile {
            // Only saving a new portrait may proceed before the regular file exists.
            guard allowMissing else { throw error }
        }
    }

    func duplicate(_ portrait: PortraitReference?, for characterID: UUID) throws -> PortraitReference? {
        guard let portrait else { return nil }
        let source = try url(for: portrait)
        let ext = source.pathExtension.isEmpty ? "jpg" : source.pathExtension
        let destination = try validatedURL(
            for: PortraitReference(relativePath: "\(characterID.uuidString).\(ext)", crop: portrait.crop),
            allowMissing: true
        )
        try fileManager.copyItem(at: source, to: destination)
        return PortraitReference(relativePath: destination.lastPathComponent, crop: portrait.crop)
    }

    func delete(_ portrait: PortraitReference) throws {
        let target = try url(for: portrait)
        try fileManager.removeItem(at: target)
    }
}

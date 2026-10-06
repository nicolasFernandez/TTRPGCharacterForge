import XCTest
@testable import TTRPGCharacterForge

final class PR115StorageTests: XCTestCase {
    // UT-PR115-INROOT-SYMLINK: a portrait alias must never read, copy, or delete another portrait.
    func testPortraitRejectsInRootAndDanglingSymlinksWithoutDeletingTarget() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = PortraitStore(baseURL: root)
        let original = try store.save(Data([7]), for: UUID())
        for (name, destination) in [("alias.jpg", original.relativePath), ("dangling.jpg", "missing.jpg")] {
            let alias = root.appendingPathComponent(name)
            try FileManager.default.createSymbolicLink(atPath: alias.path, withDestinationPath: destination)
            let reference = PortraitReference(relativePath: name, crop: .fullImage)
            XCTAssertThrowsError(try store.url(for: reference))
            XCTAssertThrowsError(try store.delete(reference))
            XCTAssertThrowsError(try store.duplicate(reference, for: UUID()))
            XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: alias.path), destination)
            XCTAssertEqual(try Data(contentsOf: store.url(for: original)), Data([7]))
        }
    }

    // UT-PR115-SPELL-THREAD: loading runs off main; success and failure return on main.
    func testSpellLoadingRunsOffMainAndDeliversResultsOnMain() async {
        for shouldFail in [false, true] {
            let finished = expectation(description: "Spell load completes")
            let repository = LocalSpellRepository(rulesRepository: ThreadCheckingRulesRepository(shouldFail: shouldFail))
            await MainActor.run {
                repository.fetchAllSpells { result in
                    XCTAssertTrue(Thread.isMainThread)
                    switch result {
                    case .success(let spells):
                        XCTAssertFalse(shouldFail)
                        XCTAssertEqual(spells.count, 0)
                    case .failure(let error):
                        XCTAssertTrue(shouldFail)
                        XCTAssertEqual(error as? RulesCatalogError, .resourceMissing("test"))
                    }
                    finished.fulfill()
                }
            }
            await fulfillment(of: [finished], timeout: 5)
        }
    }

    func testPortraitRejectsTraversalAbsoluteAndSymlinkPaths() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let portraits = root.appendingPathComponent("Portraits")
        let store = PortraitStore(baseURL: portraits)
        let saved = try store.save(Data([1]), for: UUID())
        let outside = root.appendingPathComponent("private.txt")
        try Data([2]).write(to: outside)
        try FileManager.default.createSymbolicLink(at: portraits.appendingPathComponent("link.jpg"), withDestinationURL: outside)
        for path in ["../private.txt", outside.path, "link.jpg", ".", ".."] {
            let invalid = PortraitReference(relativePath: path, crop: .fullImage)
            XCTAssertThrowsError(try store.url(for: invalid))
            XCTAssertThrowsError(try store.delete(invalid))
        }
        XCTAssertEqual(try Data(contentsOf: outside), Data([2]))
        XCTAssertEqual(try Data(contentsOf: store.url(for: saved)), Data([1]))
    }

    func testReplacementUsesDistinctFileAndPreservesOriginal() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = PortraitStore(baseURL: root)
        let id = UUID()
        let first = try store.save(Data([1]), for: id)
        let second = try store.save(Data([2]), for: id)
        XCTAssertNotEqual(first.relativePath, second.relativePath)
        XCTAssertEqual(try Data(contentsOf: store.url(for: first)), Data([1]))
        try store.delete(second)
        XCTAssertEqual(try Data(contentsOf: store.url(for: first)), Data([1]))
    }
}

private struct ThreadCheckingRulesRepository: RulesRepository {
    let shouldFail: Bool

    func catalog(locale: RulesLocale) throws -> RulesCatalog {
        XCTAssertFalse(Thread.isMainThread)
        if shouldFail { throw RulesCatalogError.resourceMissing("test") }
        return RulesCatalog(schemaVersion: 1, rulesetID: CharacterDocument.rulesetID, locale: locale.rawValue,
                            races: [], classes: [], backgrounds: [], skills: [], languages: [], equipment: [], spells: [])
    }
}

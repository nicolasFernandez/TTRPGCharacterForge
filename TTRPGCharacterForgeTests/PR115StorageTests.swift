import XCTest
import Darwin
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

    // UT-PR115-NONREGULAR: directory and FIFO references fail before any I/O or deletion.
    func testPortraitRejectsDirectoriesAndFIFOsWithoutRemovingThem() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = root.appendingPathComponent("directory.jpg")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let child = directory.appendingPathComponent("retained.txt")
        try Data([9]).write(to: child)
        let fifo = root.appendingPathComponent("pipe.jpg")
        XCTAssertEqual(mkfifo(fifo.path, S_IRUSR | S_IWUSR), 0)
        let store = PortraitStore(baseURL: root)
        for name in ["directory.jpg", "pipe.jpg"] {
            let reference = PortraitReference(relativePath: name, crop: .fullImage)
            XCTAssertThrowsError(try store.url(for: reference))
            // A permissive implementation must fail metadata validation without ever opening a FIFO.
            if (try? store.url(for: reference)) == nil {
                XCTAssertThrowsError(try store.duplicate(reference, for: UUID()))
                XCTAssertThrowsError(try store.delete(reference))
            }
            XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(name).path))
        }
        XCTAssertEqual(try Data(contentsOf: child), Data([9]))
    }

    // UT-PR115-MISSING: only new saves may accept a valid filename that does not exist.
    func testMissingPortraitCannotResolveButSaveCreatesRegularFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = PortraitStore(baseURL: root)
        let missing = PortraitReference(relativePath: "missing.jpg", crop: .fullImage)
        XCTAssertThrowsError(try store.url(for: missing))
        XCTAssertThrowsError(try store.duplicate(missing, for: UUID()))
        XCTAssertThrowsError(try store.delete(missing))
        let saved = try store.save(Data([4]), for: UUID())
        XCTAssertEqual(try Data(contentsOf: store.url(for: saved)), Data([4]))
    }

    // UT-PR115-SPELL-THREAD: loading runs off main; success and failure return on main.
    func testSpellLoadingRunsOffMainAndDeliversResultsOnMain() async {
        for shouldFail in [false, true] {
            let finished = expectation(description: "Spell load completes")
            let repository = LocalSpellRepository(
                rulesRepository: ThreadCheckingRulesRepository(shouldFail: shouldFail)
            )
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

    // UT-122-17 / CAT-122-05 / AC-122-06 / SC-122-06
    func testSpellComponentsMapFromCanonicalCatalog() async {
        let finished = expectation(description: "Canonical spell components map")
        let catalog = RulesCatalog(
            schemaVersion: RulesCatalog.supportedSchemaVersion,
            rulesetID: CharacterDocument.rulesetID,
            locale: RulesLocale.english.rawValue,
            races: [],
            classes: [],
            backgrounds: [],
            skills: [],
            languages: [],
            equipment: [],
            spells: [
                spellRule(id: "acid-splash", components: [.verbal, .somatic]),
                spellRule(id: "light", components: [.verbal, .material])
            ]
        )
        let repository = LocalSpellRepository(
            rulesRepository: ThreadCheckingRulesRepository(shouldFail: false, catalog: catalog)
        )

        repository.fetchAllSpells { result in
            switch result {
            case .success(let spells):
                let acidSplash = spells.first { $0.stableID == "acid-splash" }
                XCTAssertEqual(acidSplash?.components.verbal, true)
                XCTAssertEqual(acidSplash?.components.somatic, true)
                XCTAssertEqual(acidSplash?.components.material, false)
                let light = spells.first { $0.stableID == "light" }
                XCTAssertEqual(light?.components.verbal, true)
                XCTAssertEqual(light?.components.somatic, false)
                XCTAssertEqual(light?.components.material, true)
            case .failure(let error):
                XCTFail("Unexpected spell mapping failure: \(error)")
            }
            finished.fulfill()
        }

        await fulfillment(of: [finished], timeout: 5)
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
        try FileManager.default.createSymbolicLink(
            at: portraits.appendingPathComponent("link.jpg"),
            withDestinationURL: outside
        )
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
    let catalog: RulesCatalog?

    init(shouldFail: Bool, catalog: RulesCatalog? = nil) {
        self.shouldFail = shouldFail
        self.catalog = catalog
    }

    func catalog(locale: RulesLocale) throws -> RulesCatalog {
        XCTAssertFalse(Thread.isMainThread)
        if shouldFail { throw RulesCatalogError.resourceMissing("test") }
        return catalog ?? RulesCatalog(
            schemaVersion: 1,
            rulesetID: CharacterDocument.rulesetID,
            locale: locale.rawValue,
            races: [],
            classes: [],
            backgrounds: [],
            skills: [],
            languages: [],
            equipment: [],
            spells: []
        )
    }
}

private func spellRule(id: String, components: Set<SpellComponent>) -> SpellRule {
    SpellRule(
        id: id,
        name: id,
        level: 0,
        school: SpellSchool.evocation.rawValue,
        castingTime: "display",
        castingTimeMechanic: SpellCastingTime(amount: 1, unit: .action),
        range: "display",
        rangeMechanic: SpellRange(kind: .touch, distanceFeet: nil),
        components: "display",
        componentSet: components,
        duration: "display",
        durationMechanic: SpellDuration(kind: .instantaneous, amount: nil, unit: nil),
        description: "display",
        higherLevels: nil,
        hasHigherLevels: false,
        classIDs: [ClassType.wizard.rawValue],
        ritual: false,
        concentration: false
    )
}

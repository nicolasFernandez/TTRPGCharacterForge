//
//  TTRPGCharacterForgeTests.swift
//  TTRPGCharacterForgeTests
//
//  Created by Nicolas Alonso Fernandez Alarcon on 26-12-22.
//

import XCTest
@testable import TTRPGCharacterForge

final class TTRPGCharacterForgeTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testStandardArrayValidation() {
        let scores = AbilityScoreSet(strength: 15, dexterity: 14, constitution: 13, intelligence: 12, wisdom: 10, charisma: 8)
        XCTAssertTrue(AbilityAssignmentService().validate(scores, method: .standardArray))
        var invalid = scores
        invalid.charisma = 9
        XCTAssertFalse(AbilityAssignmentService().validate(invalid, method: .standardArray))
    }

    func testPointBuyRequiresExactlyTwentySevenPoints() {
        let valid = AbilityScoreSet(strength: 15, dexterity: 15, constitution: 15, intelligence: 8, wisdom: 8, charisma: 8)
        XCTAssertTrue(AbilityAssignmentService().validate(valid, method: .pointBuy))
        var invalid = valid
        invalid.strength = 14
        XCTAssertFalse(AbilityAssignmentService().validate(invalid, method: .pointBuy))
    }

    func testRolledScoresDropLowestDie() {
        let generator = FixedRandomNumberGenerator(values: [1, 6, 5, 4])
        let rolls = AbilityAssignmentService().rollSet(using: generator)
        XCTAssertEqual(rolls, Array(repeating: 15, count: 6))
    }

    func testAbilityModifierRoundsNegativeValuesDown() {
        XCTAssertEqual(ComputeDerivedStatsUseCase.modifier(for: 9), -1)
        XCTAssertEqual(ComputeDerivedStatsUseCase.modifier(for: 7), -2)
        XCTAssertEqual(ComputeDerivedStatsUseCase.modifier(for: 10), 0)
        XCTAssertEqual(ComputeDerivedStatsUseCase.modifier(for: 18), 4)
    }

    func testCharacterDocumentRoundTripsThroughJSON() throws {
        var character = CharacterDocument(name: "Mira")
        character.raceID = "human"
        character.classID = "wizard"
        let data = try JSONEncoder().encode(character)
        XCTAssertEqual(try JSONDecoder().decode(CharacterDocument.self, from: data), character)
    }

}

private final class FixedRandomNumberGenerator: RandomNumberGenerating {
    private let values: [Int]
    private var index = 0

    init(values: [Int]) { self.values = values }

    func next(in range: ClosedRange<Int>) -> Int {
        defer { index += 1 }
        return values[index % values.count]
    }
}

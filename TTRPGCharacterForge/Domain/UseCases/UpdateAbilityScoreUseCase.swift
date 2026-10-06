//
//  UpdateAbilityScoreUseCase.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Supplies random values for testable rolled-ability generation.
protocol RandomNumberGenerating {
    func next(in range: ClosedRange<Int>) -> Int
}

/// Adapts Swift's system random-number API to ``RandomNumberGenerating``.
struct SystemRandomNumberGeneratorAdapter: RandomNumberGenerating {
    func next(in range: ClosedRange<Int>) -> Int { Int.random(in: range) }
}

/// Creates valid score sets for the supported ability-assignment methods.
struct AbilityAssignmentService {
    static let standardArray = [15, 14, 13, 12, 10, 8]
    static let pointCosts = [8: 0, 9: 1, 10: 2, 11: 3, 12: 4, 13: 5, 14: 7, 15: 9]

    func validate(_ scores: AbilityScoreSet, method: AbilityAssignmentMethod) -> Bool {
        let values = AbilityID.allCases.map { scores[$0] }
        switch method {
        case .standardArray:
            return values.sorted() == Self.standardArray.sorted()
        case .pointBuy:
            guard values.allSatisfy({ Self.pointCosts[$0] != nil }) else { return false }
            return values.reduce(0) { $0 + Self.pointCosts[$1, default: 99] } == 27
        case .rolled:
            return values.allSatisfy { (3...18).contains($0) }
        }
    }

    func rollSet(using generator: RandomNumberGenerating = SystemRandomNumberGeneratorAdapter()) -> [Int] {
        (0..<6).map { _ in
            let rolls = (0..<4).map { _ in generator.next(in: 1...6) }
            return rolls.sorted().dropFirst().reduce(0, +)
        }
    }
}

/// Applies an ability-score change while enforcing assignment constraints.
struct UpdateAbilityScoreUseCase {
    func execute(
        character: inout CharacterDocument,
        ability: AbilityID,
        score: Int,
        method: AbilityAssignmentMethod
    ) throws {
        guard isValidScore(score, method: method) else {
            throw CharacterValidationError.invalidAbilityScores
        }
        let updated = try updatedScores(character: character, ability: ability, score: score, method: method)
        character.baseAbilities = updated
        character.abilityMethod = method
        character.updatedAt = Date()
    }
    private func isValidScore(_ score: Int, method: AbilityAssignmentMethod) -> Bool {
        switch method {
        case .standardArray: AbilityAssignmentService.standardArray.contains(score)
        case .pointBuy: AbilityAssignmentService.pointCosts[score] != nil
        case .rolled: (3...18).contains(score)
        }
    }

    private func updatedScores(
        character: CharacterDocument,
        ability: AbilityID,
        score: Int,
        method: AbilityAssignmentMethod
    ) throws -> AbilityScoreSet {
        var updated = character.abilityMethod == method ? character.baseAbilities : .zero
        if method == .standardArray { swapOwner(of: score, with: ability, scores: &updated) }
        updated[ability] = score
        try validatePointBuyBudget(updated, method: method)
        return updated
    }

    private func validatePointBuyBudget(_ scores: AbilityScoreSet, method: AbilityAssignmentMethod) throws {
        guard method == .pointBuy else { return }
        let cost = AbilityID.allCases.reduce(0) {
            $0 + AbilityAssignmentService.pointCosts[scores[$1], default: 0]
        }
        guard cost <= 27 else { throw CharacterValidationError.invalidAbilityScores }
    }

    private func swapOwner(of score: Int, with ability: AbilityID, scores: inout AbilityScoreSet) {
        if let previousOwner = AbilityID.allCases.first(where: { $0 != ability && scores[$0] == score }) {
            scores[previousOwner] = scores[ability]
        }
    }
}

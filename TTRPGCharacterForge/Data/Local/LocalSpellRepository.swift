//
//  LocalSpellRepository.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 27-10-25.
//

import Foundation
import CryptoKit

/// Loads spell data from resources bundled with the application.
final class LocalSpellRepository: SpellRepository {
    private let rulesRepository: RulesRepository

    init(rulesRepository: RulesRepository = BundledRulesRepository()) {
        self.rulesRepository = rulesRepository
    }

    func fetchAllSpells(completion: @escaping (Result<[Spell], any Error>) -> Void) {
        do {
            let catalog = try rulesRepository.catalog(locale: .current)
            completion(.success(catalog.spells.compactMap(Self.makeSpell)))
        } catch {
            completion(.failure(error))
        }
    }

    func fetchSpell(withID id: UUID, completion: @escaping (Result<Spell, any Error>) -> Void) {
        fetchAllSpells { result in
            completion(result.flatMap { spells in
                guard let spell = spells.first(where: { $0.id == id }) else {
                    return .failure(NSError(
                        domain: "LocalSpellRepository",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("spell_not_found", comment: "Spell not found")]
                    ))
                }
                return .success(spell)
            })
        }
    }

    func fetchSpells(forClass classType: ClassType, completion: @escaping (Result<[Spell], any Error>) -> Void) {
        fetchAllSpells { result in
            switch result {
            case .success(let allSpells):
                let filtered = allSpells.filter { $0.classes.contains(classType) }
                completion(.success(filtered))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchSpells(forLevel level: Int, completion: @escaping (Result<[Spell], any Error>) -> Void) {
        fetchAllSpells { result in
            switch result {
            case .success(let allSpells):
                let filtered = allSpells.filter { $0.level == level }
                completion(.success(filtered))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func searchSpells(byName name: String, completion: @escaping (Result<[Spell], any Error>) -> Void) {
        fetchAllSpells { result in
            switch result {
            case .success(let allSpells):
                let filtered = allSpells.filter { $0.name.contains(name) }
                completion(.success(filtered))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func saveSpell(_ spell: Spell, completion: @escaping (Result<Void, any Error>) -> Void) {
        completion(.failure(NSError(
            domain: "LocalSpellRepository",
            code: 405,
            userInfo: [NSLocalizedDescriptionKey: "Bundled SRD spells are read-only."]
        )))
    }

    private static func makeSpell(_ rule: SpellRule) -> Spell? {
        guard let school = SpellSchool(rawValue: rule.school),
              !rule.classIDs.isEmpty else { return nil }
        let classes = rule.classIDs.compactMap(ClassType.init(rawValue:))
        return Spell(
            id: Self.stableUUID(for: rule.id),
            stableID: rule.id,
            name: rule.name,
            level: rule.level,
            school: school,
            castingTime: rule.castingTime,
            range: rule.range,
            components: SpellComponents(
                verbal: rule.components.contains("V"),
                somatic: rule.components.contains("S"),
                material: rule.components.contains("M"),
                materialComponents: nil
            ),
            duration: rule.duration,
            levelDescription: rule.description,
            higherLevelsDescription: rule.higherLevels,
            classes: classes,
            isRitual: rule.ritual,
            requiresConcentration: rule.concentration
        )
    }

    private static func stableUUID(for value: String) -> UUID {
        let digest = SHA256.hash(data: Data(value.utf8))
        let bytes = Array(digest.prefix(16))
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}

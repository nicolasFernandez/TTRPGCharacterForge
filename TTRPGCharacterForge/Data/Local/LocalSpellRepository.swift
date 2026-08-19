//
//  LocalSpellRepository.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 27-10-25.
//

import Foundation

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
                    return .failure(NSError(domain: "LocalSpellRepository", code: 404))
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
}

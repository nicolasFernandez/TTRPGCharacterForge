//
//  SpellListViewModel.swift
//  TTRPGCharacterForge
//
//  Created on 2025-10-13.
//

import Foundation
import Combine

/// Loads, searches, and filters spells for presentation.
final class SpellListViewModel: ObservableObject {
    private let spellUseCase: SpellUseCase
    
    @Published var spells: [Spell] = []
    @Published var filteredSpells: [Spell] = []
    @Published var selectedClassFilter: ClassType?
    @Published var selectedLevelFilter: Int?
    @Published var selectedSchoolFilter: SpellSchool?
    @Published var ritualsOnly = false
    @Published var concentrationOnly = false
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init(spellUseCase: SpellUseCase) {
        self.spellUseCase = spellUseCase
    }
    
    func loadSpells() {
        isLoading = true
        errorMessage = nil
        
        spellUseCase.getAllSpells { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let spells):
                    self.spells = spells
                    self.applyFilters()
                case .failure(let error):
                    self.errorMessage = "Failed to load spells: \(error.localizedDescription)"
                }
                
                self.isLoading = false
            }
        }
    }
    
    func filterByClass(_ classType: ClassType?) {
        selectedClassFilter = classType
        applyFilters()
    }
    
    func filterByLevel(_ level: Int?) {
        selectedLevelFilter = level
        applyFilters()
    }
    
    func search(query: String) {
        searchText = query
        
        applyFilters()
    }

    func filterBySchool(_ school: SpellSchool?) { selectedSchoolFilter = school; applyFilters() }
    func setRitualsOnly(_ value: Bool) { ritualsOnly = value; applyFilters() }
    func setConcentrationOnly(_ value: Bool) { concentrationOnly = value; applyFilters() }
    
    private func applyFilters() {
        let normalizedQuery = searchText.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        filteredSpells = spells.filter { spell in
            let matchesName = normalizedQuery.isEmpty || spell.name
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .contains(normalizedQuery)
            return matchesName
                && (selectedClassFilter == nil || spell.classes.contains(selectedClassFilter!))
                && (selectedLevelFilter == nil || spell.level == selectedLevelFilter!)
                && (selectedSchoolFilter == nil || spell.school == selectedSchoolFilter!)
                && (!ritualsOnly || spell.isRitual)
                && (!concentrationOnly || spell.requiresConcentration)
        }
    }
}

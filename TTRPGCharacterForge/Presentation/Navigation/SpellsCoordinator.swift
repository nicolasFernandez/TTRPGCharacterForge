//
//  SpellsCoordinator.swift
//  TTRPGCharacterForge
//
//  Created on 2025-10-13.
//

import SwiftUI

/// Coordinator responsible for managing navigation and dependency injection for the Spells feature
final class SpellsCoordinator {
    private let spellUseCase: SpellUseCase
    
    init(spellUseCase: SpellUseCase) {
        self.spellUseCase = spellUseCase
    }
    
    /// Creates the main entry point for the Spells feature
    @ViewBuilder
    func makeSpellsView() -> some View {
        let viewModel = SpellListViewModel(spellUseCase: spellUseCase)
        SpellListView(viewModel: viewModel)
    }
    
    /// Factory method to create a spell detail view
    @ViewBuilder
    func makeSpellDetailView(for spell: Spell) -> some View {
        SpellDetailView(spell: spell)
    }
}

// Extension to help with dependency injection in SwiftUI previews
extension SpellsCoordinator {
    static var preview: SpellsCoordinator {
        let repository = LocalSpellRepository()
        let useCase = SpellUseCase(repository: repository)
        return SpellsCoordinator(spellUseCase: useCase)
    }
}

//
//  SpellListView.swift
//  TTRPGCharacterForge
//
//  Created on 2025-10-13.
//

import SwiftUI

/// Displays a searchable and filterable list of spells.
struct SpellListView: View {
    @StateObject var viewModel: SpellListViewModel
    @State private var searchText = ""
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack {
                TextField(
                    NSLocalizedString("spell_search_text", comment: ""),
                    text: $searchText,
                    onEditingChanged: { _ in },
                    onCommit: { viewModel.search(query: searchText) })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: searchText) { _, newValue in
                    viewModel.search(query: newValue)
                }
                
                content
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadSpells()
            }
        }
    }

    var content: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if viewModel.filteredSpells.isEmpty {
                Text(
                    NSLocalizedString("spell_not_found", comment: "")
                )
                .foregroundColor(.secondary)
                .padding()
            } else {
                List {
                    ForEach(viewModel.filteredSpells) { spell in
                        NavigationLink(destination: SpellDetailView(spell: spell)) {
                            SpellRowView(spell: spell)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle(NSLocalizedString("spells_title", comment: ""))
    }
}

struct SpellListView_Previews: PreviewProvider {
    static var previews: some View {
        let repository = LocalSpellRepository()
        let useCase = SpellUseCase(repository: repository)
        let viewModel = SpellListViewModel(spellUseCase: useCase)
        SpellListView(viewModel: viewModel)
    }
}

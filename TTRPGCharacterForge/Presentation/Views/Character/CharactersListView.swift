import SwiftUI

/// Displays saved characters and entry points for character management.
struct CharactersListView: View {
    let compositionRoot: CompositionRoot
    @StateObject private var viewModel: CharacterListViewModel
    @State private var editor: EditorDestination?

    init(compositionRoot: CompositionRoot) {
        self.compositionRoot = compositionRoot
        _viewModel = StateObject(wrappedValue: compositionRoot.makeCharacterListViewModel())
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.characters.isEmpty {
                ProgressView()
            } else if viewModel.characters.isEmpty {
                ContentUnavailableView(
                    "characters_empty_title",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text("characters_empty_description")
                )
            } else {
                List {
                    characterSection(title: "characters_drafts", values: drafts)
                    characterSection(title: "characters_completed", values: completed)
                }
            }
        }
        .navigationTitle("characters_title")
        .toolbar {
            Button { editor = EditorDestination(character: nil) } label: {
                Label("character_create", systemImage: "plus")
            }
        }
        .task { viewModel.loadCharacters() }
        .refreshable { viewModel.loadCharacters() }
        .sheet(item: $editor, onDismiss: viewModel.loadCharacters) { destination in
            editorView(for: destination.character)
        }
        .alert("error_title", isPresented: errorBinding) {
            Button("ok", role: .cancel) { viewModel.errorMessage = nil }
        } message: { Text(viewModel.errorMessage ?? "") }
    }

    private var drafts: [CharacterDocument] { viewModel.characters.filter { $0.state == .draft } }
    private var completed: [CharacterDocument] { viewModel.characters.filter { $0.state == .completed } }

    @ViewBuilder
    private func characterSection(title: LocalizedStringKey, values: [CharacterDocument]) -> some View {
        if !values.isEmpty {
            Section(title) {
                ForEach(values) { character in
                    Button { editor = EditorDestination(character: character) } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(character.name.isEmpty ? String(localized: "character_unnamed") : character.name)
                                    .font(.headline)
                                Text(character.classID ?? String(localized: "character_incomplete"))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if character.state == .draft { Text("character_resume").font(.caption) }
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { viewModel.delete(character) } label: {
                            Label("delete", systemImage: "trash")
                        }
                        Button { viewModel.duplicate(character) } label: {
                            Label("duplicate", systemImage: "plus.square.on.square")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
    }

    private func editorView(for character: CharacterDocument?) -> AnyView {
        do {
            let viewModel = try compositionRoot.makeCharacterEditorViewModel(character: character)
            return AnyView(CreateCharacterView(viewModel: viewModel))
        } catch {
            return AnyView(ContentUnavailableView("error_title", systemImage: "exclamationmark.triangle", description: Text(error.localizedDescription)))
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }
}

private struct EditorDestination: Identifiable {
    let id = UUID()
    let character: CharacterDocument?
}

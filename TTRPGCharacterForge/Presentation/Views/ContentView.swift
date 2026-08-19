import SwiftUI

/// Universal distribution root. Phone and tablet keep independent compositions
/// while sharing the same domain and repositories.
struct ContentView: View {
    let compositionRoot: CompositionRoot
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            TabletRootView(compositionRoot: compositionRoot)
        } else {
            PhoneRootView(compositionRoot: compositionRoot)
        }
    }
}

private struct PhoneRootView: View {
    let compositionRoot: CompositionRoot

    var body: some View {
        TabView {
            NavigationStack { CharactersListView(compositionRoot: compositionRoot) }
                .tabItem { Label("characters_title", systemImage: "person.2") }
            NavigationStack { compositionRoot.spellsCoordinator.makeSpellsView() }
                .tabItem { Label("spells_title", systemImage: "book.closed") }
            NavigationStack { SettingsView() }
                .tabItem { Label("settings_title", systemImage: "gear") }
        }
    }
}

private struct TabletRootView: View {
    enum Section: String, CaseIterable, Identifiable {
        case characters, spells, settings
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .characters: "person.2"
            case .spells: "book.closed"
            case .settings: "gear"
            }
        }
    }

    let compositionRoot: CompositionRoot
    @State private var selection: Section? = .characters

    var body: some View {
        NavigationSplitView {
            List(Section.allCases, selection: $selection) { section in
                Label(LocalizedStringKey("\(section.rawValue)_title"), systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("app_name")
        } detail: {
            switch selection ?? .characters {
            case .characters: CharactersListView(compositionRoot: compositionRoot)
            case .spells: compositionRoot.spellsCoordinator.makeSpellsView()
            case .settings: SettingsView()
            }
        }
    }
}

private struct SettingsView: View {
    var body: some View {
        Form {
            Section("settings_data_title") {
                Label("settings_offline_description", systemImage: "iphone")
            }
            Section("settings_legal_title") {
                Text("settings_srd_attribution")
                NavigationLink("settings_license") {
                    ScrollView { Text("settings_license_summary").padding() }
                        .navigationTitle("settings_license")
                }
            }
        }
        .navigationTitle("settings_title")
    }
}

import SwiftUI
import PhotosUI

/// Presents the guided workflow for creating and saving a character.
struct CreateCharacterView: View {
    @StateObject var viewModel: CharacterEditorVM
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ProgressView(
                        value: Double(viewModel.character.currentStep.rawValue + 1),
                        total: Double(CharacterCreationStep.allCases.count)
                    )
                    Text(stepTitle).font(.headline)
                }
                stepContent
                if let error = viewModel.errorMessage {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            //FIXME: Ensure the empty-name navigation title uses a localized value instead of displaying its raw key. + https://github.com/nicolasFernandez/TTRPGCharacterForge/pull/115#discussion_r3814262737
            .navigationTitle(viewModel.character.name.isEmpty ? String(localized: "character_create") : viewModel.character.name)
            //FIXME: Keep the navigation title and toolbar attached to the Form or NavigationStack rather than child content. + https://github.com/nicolasFernandez/TTRPGCharacterForge/pull/115#discussion_r3814395276
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("done") { viewModel.autosave(); dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { navigationBar }
        }
    }

    @ViewBuilder private var stepContent: some View {
        switch viewModel.character.currentStep {
        case .identity: identityStep
        case .ancestry: ancestryStep
        case .characterClass: classStep
        case .background: backgroundStep
        case .abilities: abilitiesStep
        case .proficiencies: proficienciesStep
        case .equipment: equipmentStep
        case .spells: spellsStep
        case .portrait: portraitStep
        case .review: reviewStep
        }
    }

    private var identityStep: some View {
        Section("character_identity") {
            TextField("character_name", text: $viewModel.character.name)
            TextField("character_player_name", text: $viewModel.character.playerName)
            TextField("character_appearance", text: $viewModel.character.appearance, axis: .vertical)
        }
    }

    private var ancestryStep: some View {
        Section("character_race") {
            Picker("character_race", selection: $viewModel.character.raceID) {
                Text("choose_prompt").tag(String?.none)
                ForEach(viewModel.races) { Text($0.name).tag(Optional($0.id)) }
            }
            .onChange(of: viewModel.character.raceID) { _, _ in
                viewModel.character.subraceID = nil
                viewModel.applyRaceBonuses()
            }
            if let race = viewModel.races.first(where: { $0.id == viewModel.character.raceID }), !race.subraces.isEmpty {
                Picker("character_subrace", selection: $viewModel.character.subraceID) {
                    Text("choose_prompt").tag(String?.none)
                    ForEach(race.subraces) { Text($0.name).tag(Optional($0.id)) }
                }
            }
        }
    }

    private var classStep: some View {
        Section("character_class") {
            Picker("character_class", selection: $viewModel.character.classID) {
                Text("choose_prompt").tag(String?.none)
                ForEach(viewModel.classes) { Text($0.name).tag(Optional($0.id)) }
            }
            if let rule = viewModel.classes.first(where: { $0.id == viewModel.character.classID }), !rule.archetypes.isEmpty {
                Picker("character_archetype", selection: $viewModel.character.archetypeID) {
                    Text("choose_prompt").tag(String?.none)
                    ForEach(rule.archetypes) { Text($0.name).tag(Optional($0.id)) }
                }
            }
        }
    }

    private var backgroundStep: some View {
        Section("character_background") {
            Picker("character_background", selection: $viewModel.character.backgroundID) {
                Text("choose_prompt").tag(String?.none)
                ForEach(viewModel.backgrounds) { Text($0.name).tag(Optional($0.id)) }
            }
            .onChange(of: viewModel.character.backgroundID) { _, newValue in
                guard let rule = viewModel.backgrounds.first(where: { $0.id == newValue }) else { return }
                viewModel.character.selectedSkillIDs = Array(Set(viewModel.character.selectedSkillIDs + rule.grantedSkillIDs))
                viewModel.character.selectedLanguageIDs = Array(Set(viewModel.character.selectedLanguageIDs + rule.grantedLanguageIDs))
                viewModel.character.selectedEquipmentIDs = Array(Set(viewModel.character.selectedEquipmentIDs + rule.grantedEquipmentIDs))
                viewModel.autosave()
            }
            TextField("character_traits", text: $viewModel.character.personality.traits, axis: .vertical)
            TextField("character_ideals", text: $viewModel.character.personality.ideals, axis: .vertical)
            TextField("character_bonds", text: $viewModel.character.personality.bonds, axis: .vertical)
            TextField("character_flaws", text: $viewModel.character.personality.flaws, axis: .vertical)
        }
    }

    private var abilitiesStep: some View {
        AbilityAssignmentView(viewModel: viewModel)
    }

    private var proficienciesStep: some View {
        Section("character_proficiencies") {
            if let rule = viewModel.classes.first(where: { $0.id == viewModel.character.classID }) {
                Text(String(format: NSLocalizedString("character_choose_skills", comment: ""), rule.skillChoiceCount))
                ForEach(viewModel.skills.filter { rule.availableSkillIDs.contains($0.id) }) { skill in
                    Toggle(skill.name, isOn: Binding(
                        get: { viewModel.character.selectedSkillIDs.contains(skill.id) },
                        set: { _ in viewModel.toggleSkill(skill.id) }
                    ))
                }
            } else { Text("character_choose_class_first") }
        }
    }

    private var equipmentStep: some View {
        Section("character_equipment") {
            Text("character_equipment_guidance")
            ForEach(viewModel.equipment) { item in
                Toggle(item.name, isOn: Binding(
                    get: { viewModel.character.selectedEquipmentIDs.contains(item.id) },
                    set: { _ in viewModel.toggleEquipment(item.id) }
                ))
            }
            TextField("character_starting_gold", value: Binding(
                get: { viewModel.character.startingWealthGP ?? 0 },
                set: {
                    viewModel.character.startingWealthGP = $0 > 0 ? $0 : nil
                    if $0 > 0 { viewModel.character.selectedEquipmentIDs = [] }
                    viewModel.autosave()
                }
            ), format: .number)
                .keyboardType(.numberPad)
        }
    }

    private var spellsStep: some View {
        Section("spells_title") {
            if viewModel.spells.isEmpty {
                Text("character_no_spells")
            } else {
                Text("character_spells_guidance")
                ForEach(viewModel.spells) { spell in
                    Toggle("\(spell.name) · \(spell.level == 0 ? String(localized: "cantrip_text") : String(format: NSLocalizedString("level_text", comment: ""), spell.level))", isOn: Binding(
                        get: { viewModel.character.selectedSpellIDs.contains(spell.id) },
                        set: { _ in viewModel.toggleSpell(spell.id) }
                    ))
                }
            }
        }
    }

    private var portraitStep: some View {
        Section("character_portrait") {
            Text("character_portrait_import_guidance")
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("character_choose_portrait", systemImage: "photo")
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        viewModel.importPortrait(data)
                    }
                }
            }
            if viewModel.character.portrait != nil {
                Label("character_portrait_saved", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private var reviewStep: some View {
        Section("character_review") {
            LabeledContent("character_name", value: viewModel.character.name)
            LabeledContent("character_race", value: viewModel.character.raceID ?? "—")
            LabeledContent("character_class", value: viewModel.character.classID ?? "—")
            if let stats = viewModel.derivedStats {
                LabeledContent("character_armor_class", value: "\(stats.armorClass)")
                LabeledContent("character_hit_points", value: "\(stats.hitPoints)")
            }
            DisclosureGroup("character_overrides") {
                TextField("character_armor_class", value: Binding(
                    get: { viewModel.character.overrides.armorClass ?? viewModel.derivedStats?.armorClass ?? 10 },
                    set: { viewModel.character.overrides.armorClass = $0; viewModel.autosave() }
                ), format: .number)
                TextField("character_hit_points", value: Binding(
                    get: { viewModel.character.overrides.hitPoints ?? viewModel.derivedStats?.hitPoints ?? 1 },
                    set: { viewModel.character.overrides.hitPoints = $0; viewModel.autosave() }
                ), format: .number)
                TextField("character_initiative", value: Binding(
                    get: { viewModel.character.overrides.initiative ?? viewModel.derivedStats?.initiative ?? 0 },
                    set: { viewModel.character.overrides.initiative = $0; viewModel.autosave() }
                ), format: .number)
                Button("character_reset_overrides") {
                    viewModel.character.overrides = CharacterOverrides()
                    viewModel.autosave()
                }
            }
            Button("character_prepare_exports") { viewModel.prepareExports() }
            if let pdf = viewModel.exportedPDF {
                ShareLink(item: pdf) { Label("character_share_pdf", systemImage: "doc") }
            }
            if let token = viewModel.exportedToken {
                ShareLink(item: token) { Label("character_share_token", systemImage: "circle.inset.filled") }
            }
            Button("character_complete") {
                Task { if await viewModel.complete() { dismiss() } }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var navigationBar: some View {
        HStack {
            Button("back") { viewModel.goBack() }
                .disabled(viewModel.character.currentStep == .identity)
            Spacer()
            if viewModel.character.currentStep != .review {
                Button("next") { viewModel.advance() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding().background(.bar)
    }

    private var stepTitle: LocalizedStringKey {
        LocalizedStringKey("character_step_\(viewModel.character.currentStep.rawValue)")
    }
}

private struct AbilityAssignmentView: View {
    @ObservedObject var viewModel: CharacterEditorVM
    @State private var method: AbilityAssignmentMethod = .standardArray

    var body: some View {
        Section("character_abilities") {
            Picker("character_ability_method", selection: $method) {
                ForEach(AbilityAssignmentMethod.allCases, id: \.self) {
                    Text(LocalizedStringKey("ability_method_\($0.rawValue)")).tag($0)
                }
            }
            .onChange(of: method) { _, newMethod in configure(newMethod) }
            if method == .pointBuy {
                LabeledContent("ability_points_remaining", value: "\(max(0, 27 - pointCost))")
            }
            ForEach(AbilityID.allCases) { ability in
                //FIXME: Localize the ability name in the Stepper label instead of interpolating its raw value. + https://github.com/nicolasFernandez/TTRPGCharacterForge/pull/115#discussion_r3814262774
                Stepper(
                    "\(ability.rawValue.capitalized): \(viewModel.character.baseAbilities[ability])",
                    value: Binding(
                        get: { viewModel.character.baseAbilities[ability] },
                        set: { viewModel.setAbility(ability, score: $0, method: method) }
                    ),
                    in: method == .pointBuy ? 8...15 : 3...18
                )
            }
            if method == .standardArray { Button("ability_apply_standard") { applyStandard() } }
            if method == .rolled { Button("ability_roll") { applyRolls() } }
        }
    }

    private func applyStandard() {
        for (ability, score) in zip(AbilityID.allCases, AbilityAssignmentService.standardArray) {
            viewModel.setAbility(ability, score: score, method: .standardArray)
        }
    }

    private func applyRolls() {
        for (ability, score) in zip(AbilityID.allCases, AbilityAssignmentService().rollSet()) {
            viewModel.setAbility(ability, score: score, method: .rolled)
        }
    }

    private var pointCost: Int {
        AbilityID.allCases.reduce(0) {
            $0 + AbilityAssignmentService.pointCosts[viewModel.character.baseAbilities[$1], default: 99]
        }
    }

    private func configure(_ method: AbilityAssignmentMethod) {
        switch method {
        case .standardArray: applyStandard()
        case .pointBuy:
            for ability in AbilityID.allCases { viewModel.setAbility(ability, score: 8, method: .pointBuy) }
        case .rolled: applyRolls()
        }
    }
}

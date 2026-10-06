//
//  AbilityScoresView.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 16-01-23.
//

import SwiftUI
// TODO: complete, this is just a testing WIP
/// Displays a character's six core ability scores.
struct AbilityScoresView: View {
    let options = Array(1...30)
    @State private var selectedOption = 0
    let name: String
    let bonus: Int
    var body: some View {
        VStack {
            Text(name).bold()
            // Value
            Picker(name, selection: $selectedOption) {
                ForEach(options.indices, id: \.self) {
                    Text("\(self.options[$0])").tag($0)
                }
            }
            let total = options[selectedOption] + bonus
            Text("Total: \(total)").bold()
            // Modifier

        }
    }
}

struct AbilityScoresView_Previews: PreviewProvider {
    static var previews: some View {
        AbilityScoresView(
            name: NSLocalizedString("Strength", comment: ""),
            bonus: 2
        )
    }
}

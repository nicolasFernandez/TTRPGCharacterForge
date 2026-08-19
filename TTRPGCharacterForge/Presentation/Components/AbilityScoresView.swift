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
    let options = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]
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

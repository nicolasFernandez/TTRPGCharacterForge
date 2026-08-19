//
//  SpellRowView.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 14-10-25.
//

import SwiftUI

/// Summarizes a spell for display in a list.
struct SpellRowView: View {
    let spell: Spell
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(spell.name)
                    .font(.headline)
                
                Spacer()
                
                Text(spell.levelString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(spell.school.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct SpellRowView_Previews: PreviewProvider {
    static var previews: some View {
        let spell = Spell(
            name: "Hechizo",
            level: 0,
            school: .abjuration,
            castingTime: "1 ronda",
            range: "alcance",
            components: SpellComponents(
                verbal: true,
                somatic: true,
                material: true,
                materialComponents: "Saquito colgante"
            ),
            duration: "1 hora",
            levelDescription: "Haces un hechizo que dura una hora", higherLevelsDescription: nil,
            classes: [.bard, .cleric, .warlock]
        )

        SpellRowView(spell: spell)
    }
}

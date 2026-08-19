//
//  SchoolRow.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 13-01-23.
//

import SwiftUI

/// Displays the available spell schools as filter choices.
struct SpellSchoolView: View {
    var spellSchool: SpellSchool
    var body: some View {
        HStack {
            Text(spellSchool.name)
                .font(.title)
                .fontWeight(.bold)
                .padding(
                    .trailing, 30
                )
            Spacer()
        }
    }
}

struct SchoolRow_Previews: PreviewProvider {
    static var previews: some View {
        SpellSchoolView(
            spellSchool: .abjuration
        ).previewLayout(.fixed(width: 500, height: 100))
    }
}

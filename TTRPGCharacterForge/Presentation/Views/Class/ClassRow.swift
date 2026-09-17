//
//  ClassRow.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 13-01-23.
//

import SwiftUI

/// Summarizes a character class for display in a list.
struct ClassRow: View {
    var classType: ClassType
    var body: some View {
        HStack {
            Text(classType.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(
                    .trailing, 30
                )
        }
    }
}

struct ClassRow_Previews: PreviewProvider {
    static var previews: some View {
        ClassRow(classType: .warlock).previewLayout(.fixed(width: 500, height: 100))
    }
}

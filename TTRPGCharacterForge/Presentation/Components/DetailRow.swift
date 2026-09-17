//
//  DetailRow.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 13-10-25.
//

import SwiftUI

/// Displays a labeled value in a details screen.
struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.headline)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct DetailRow_Previews: PreviewProvider {
    static var previews: some View {
        DetailRow(title: "Title", value: "Value")
    }
}

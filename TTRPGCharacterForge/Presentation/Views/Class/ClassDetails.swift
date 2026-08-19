//
//  ClassDetails.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 13-01-23.
//

import SwiftUI

/// Presents the game rules and features for a character class.
struct ClassDetails: View {
    var classType: ClassType
    var body: some View {
        ScrollView {
            VStack (alignment: .leading, spacing: 16) {
                ClassRow(classType: classType)
                Text(classType.description)
                Text(
                    NSLocalizedString(
                        "Class Features",
                        comment: ""
                    )
                )
                .font(.title)
                .fontWeight(.bold)
                DetailRow(
                    title: NSLocalizedString("Primary Ability", comment: ""),
                    value: classType.primaryAbility)
                Text("Hit Points")
                    .font(.title2)
                    .fontWeight(.bold)
                DetailRow(
                    title: NSLocalizedString("Hit Dice", comment: ""),
                    value: "1d\(classType.hitDie) per \(classType.name) level"
                )
                DetailRow(
                    title: NSLocalizedString("Hit Points at 1st Level", comment: ""),
                    value: "1d\(classType.hitDie)"
                )
                DetailRow(
                    title: NSLocalizedString("Hit Points at Higher Levels", comment: ""),
                    value: "1d\(classType.hitDie)"
                )
                Text("Proficiencies")
                    .font(.title2)
                    .fontWeight(.bold)
                DetailRow(
                    title: NSLocalizedString("Armor", comment: ""),
                    value: classType.primaryAbility)
                DetailRow(
                    title: NSLocalizedString("Weapons", comment: ""),
                    value: classType.primaryAbility)
                DetailRow(
                    title: NSLocalizedString("Tools", comment: ""),
                    value: classType.primaryAbility)
                DetailRow(
                    title: NSLocalizedString("Saving Throws", comment: ""),
                    value: classType.saves
                )
                DetailRow(
                    title: NSLocalizedString("Skills", comment: ""),
                    value: classType.saves
                )
                Text("Equipment")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("You start with the following equipment, in addition to the equipment granted by your background:")
                Text("·(a) a .... or (b) ...")
                Text("·(a) a .... or (b) ...")
                Text("·(a) a .... or (b) ...")
                Text("·Something else")
            }
            .padding()
        }
    }
}

struct ClassDetails_Previews: PreviewProvider {
    static var previews: some View {
        ClassDetails(classType: .wizard)
    }
}
